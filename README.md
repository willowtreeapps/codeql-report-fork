# felickz/codeql-report GitHub Action

This action allows you to generate a CodeQL report.

## Usage

To use the `felickz/codeql-report` action, you need to set it up in a workflow file (`.github/workflows/codeql-report.yml`).

Here's a basic example:

```yaml
name: CodeQL Report

on:
  push:
    paths:
      - '.github/workflows/codeql-report.yml'
  workflow_dispatch:
  #every 6 hours
  schedule:
    - cron: '0 */6 * * *'

jobs:
  run-report:
    runs-on: ubuntu-latest

    steps:
    - name: Use felickz/codeql-report action
      uses: felickz/codeql-report@v1
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
    - name: Upload CodeQL Report CSV as Artifact
      uses: actions/upload-artifact@v3
      with:
        name: "CodeQLReport-${{ github.run_id }}"
        path: ./*.csv
```

In this example, the felickz/codeql-report action is used

The github-token input is required for the felickz/codeql-report action. It uses the GITHUB_TOKEN secret, which is automatically created by GitHub for your repository.

## Inputs
### github-token
Required The GitHub token to authenticate and pull CodeQL Action workflow status with.
### organization
Optional The GitHub Organization. Defaults to the current Organization.
