<#
.SYNOPSIS
    This script retrieves the CodeQL workflow runs for repositories in a specified GitHub organization and generates a summary report in Markdown format.

.DESCRIPTION
    The report includes the conclusion, workflow URL, whether the workflow is the default one, organization name, repository name, and workflow path. The script also checks if the FormatMarkdownTable module is installed and installs it if necessary. Finally, it converts the summary report to Markdown format and outputs it to the GITHUB_STEP_SUMMARY environment variable. If the script is not running in a GitHub Actions environment, it also outputs the summary report to the console.

.PARAMETER GitHubToken
    The GitHub PAT that is used to authenticate to GitHub GH CLI (uses the envioronment value GH_TOKEN).

.PARAMETER GitHubOrganization
    The GitHub organization that the script will operate on. Defaults to the current Organization if not provided.

.EXAMPLE
    .\action.ps1 -GitHubToken "your_token_here" -GitHubOrganization "your_organization_here"

.NOTES
    Be careful not to expose your GitHub PAT in your workflow or any public places because it can be used to access your GitHub account.

.LINK
    For more information about GitHub Actions, visit: https://docs.github.com/en/actions.
    For information about composite actions, visit: https://docs.github.com/en/actions/creating-actions/creating-a-composite-action.
    For information about the GH CLI, visit: https://cli.github.com/manual/gh_api.

#>

param(
    [string]$GitHubToken,
    [string]$GitHubOrganization
)

# set the GH_TOKEN environment variable to the value of the GitHubToken parameter
if (![String]::IsNullOrWhiteSpace($GitHubToken)) {
    $env:GH_TOKEN = $GitHubToken
}

# Set GitHubOrganization from GITHUB_REPOSITORY_OWNER environment variable if not already set
if ([String]::IsNullOrWhiteSpace($GitHubOrganization)) {
    if ($null -ne $env:GITHUB_REPOSITORY_OWNER) {
        $GitHubOrganization = $env:GITHUB_REPOSITORY_OWNER
    }
}

$csv = "CodeQLWorkflowStatus.csv"
$header = "Conclusion,Workflow_Url,Is_Default,Org,Repo,Workflow_Path"
Set-Content -Path "./$csv" -Value $header

gh api /orgs/$GitHubOrganization/repos --paginate `
| jq -r '.[] | .name' `
| %{ `
    $repoName = $_; gh api /repos/$GitHubOrganization/$_/actions/workflows --paginate `
    # Need jq -c (compact) so that the JSON removes newlines and can be converted below `
    | jq -c '.workflows[] | select(.name=="CodeQL") | {id: .id, path: .path}' `
    | %{ `
        $workflow = $_ | ConvertFrom-Json; `
        gh api /repos/$GitHubOrganization/$repoName/actions/workflows/$($workflow.id)/runs?exclude_pull_requests=true `
        } `
    | jq -r '.workflow_runs[0] | "\(.conclusion),\(.html_url)"' `
    | %{ "$_,$($workflow.path.StartsWith("dynamic/")),$GitHubOrganization,$repoName,$($workflow.path)" } `
    | Add-Content -Path "./$csv" `
}

#TODO move to a manifest like choco package.config
if (Get-Module -ListAvailable -Name FormatMarkdownTable -ErrorAction SilentlyContinue) {
    Write-Output "FormatMarkdownTable module is installed"
}
else {
    # Handle `Untrusted repository` prompt
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    #directly to output here before module loaded to support Write-ActionInfo
    Write-Output "FormatMarkdownTable module is not installed.  Installing from Gallery..."
    Install-Module -Name FormatMarkdownTable
}

$markdownSummary = Import-Csv -Path "./$csv" | Format-MarkdownTableTableStyle -ShowMarkdown -DoNotCopyToClipboard -HideStandardOutput
$markdownSummary > $env:GITHUB_STEP_SUMMARY

if ($null -eq $env:GITHUB_ACTIONS) {
    $markdownSummary
}