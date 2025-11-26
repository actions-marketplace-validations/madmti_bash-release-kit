# Bash Release Kit

A zero-dependency, pure Bash release automation tool for Git repositories. It analyzes commit history based on commit messages, creates Git tags, GitHub releases, and can update version numbers in specified files.

Designed to be lightweight and fast, running natively on GitHub Actions without the need for Node.js, Python, or Docker containers.

## Quick Start (GitHub Action)

The easiest way to use this tool is as a GitHub Action step.

### Create the Workflow

Create a file at `.github/workflows/release.yml`:

```yaml
name: Release

on:
    push:
        branches:
            - main

permissions:
    contents: write # Required to create tags and releases

jobs:
    release:
        runs-on: ubuntu-latest
        steps:
            - name: Checkout Code
              uses: actions/checkout@v4
              with:
                  fetch-depth: 0 # Important: Required to calculate version history

            - name: Semantic Release
              uses: madmti/release-kit@v1
              with:
                  github_token: ${{ secrets.GITHUB_TOKEN }}
                  # Optional (Default: release-config.json)
                  # config_file: 'release-config.json'
```

That's it! On every push to the `main` branch, the action will analyze commit messages, create a new Git tag, and publish a GitHub release if applicable.

## Config File

The release kit uses a configuration file to define version update behavior and other settings. By default, it looks for `release-config.json` in the repository root. You can specify a different file using the `config_file` input in the GitHub Action.

### Basic Configuration

Create a `release-config.json` file:

```json
{
    "$schema": "https://raw.githubusercontent.com/madmti/release-kit/main/release-schema.json",
    "github": {
        "active": true
    }
}
```

Use the `$schema` property to enable schema validation in compatible editors. note that this URL points to the latest version of the schema. For stability, you may want to link to a specific version.

e.g., `https://raw.githubusercontent.com/madmti/release-kit/v1.0.0/release-schema.json`
