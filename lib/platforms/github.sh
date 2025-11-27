#!/usr/bin/env bash
#
# GitHub Platform Integration Module
#
# Provides functions for creating GitHub releases using the GitHub CLI.
# This module is loaded conditionally when GitHub integration is enabled
# in the configuration. Handles release creation with proper error handling.
#
# Functions:
#   - check_gh_cli()      Validates GitHub CLI availability
#   - create_gh_release() Creates GitHub release with tag and notes
#
# Dependencies:
#   - gh (GitHub CLI tool)
#   - log.sh (for logging functions)
#
# Environment Variables:
#   GITHUB_TOKEN - Required for GitHub CLI authentication

#######################################
# Verify GitHub CLI tool is installed and available
# Checks if the 'gh' command is available in PATH. Required for GitHub
# release creation functionality.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   Does not return on failure (script exits via log_fatal)
# Exits:
#   1 if GitHub CLI is not installed
#######################################
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log_fatal "GitHub CLI (gh) is not installed. Please install it to proceed."
    fi
}

#######################################
# Create GitHub release with specified tag and release notes
# Creates a new GitHub release using the GitHub CLI with the provided
# tag name and release notes. Falls back to automated message if notes are empty.
# Globals:
#   None
# Arguments:
#   $1: tag - Git tag name for the release (e.g., "v1.2.3")
#   $2: notes - Release notes content (markdown format supported)
# Outputs:
#   Progress information via log_info
#   GitHub CLI output to stdout/stderr
# Returns:
#   0 on success, non-zero on GitHub CLI failure
# Notes:
#   - Requires GITHUB_TOKEN environment variable for authentication
#   - Tag must already exist in the repository
#   - Release title will match the tag name
#######################################
create_gh_release() {
    local tag="$1"
    local notes="$2"

    # Provide default notes if none specified
    if [ -z "$notes" ]; then
            notes="Automated release $tag"
    fi

    log_info "Creating GitHub release for tag $tag"
    gh release create "$tag" \
        --title "$tag" \
        --notes "$notes"
}
