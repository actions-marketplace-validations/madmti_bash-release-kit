#!/usr/bin/env bash
#
# Changelog Generation Module
#
# Provides functions for generating and formatting changelog content from commit messages.
# Processes conventional commits to create structured release notes and maintains
# a cumulative changelog file. Supports custom commit type configurations and
# automatic section organization.
#
# Functions:
#   - _filter_commits_by_type() Filter commits by conventional commit type
#   - get_notes()               Generate formatted release notes from commits
#   - write_changelog()         Write release notes to changelog file
#
# Dependencies:
#   - jq (for JSON parsing of commit type configuration)
#   - grep (for commit message filtering)
#   - sed (for text formatting)
#   - date (for timestamp generation)
#   - config.sh (for get_commit_types function)
#   - log.sh (for logging functions)

CHANGELOG_FILE="CHANGELOG.md"

#######################################
# Filter commit messages by conventional commit type
# Extracts commit messages that match a specific conventional commit type.
# Uses grep with extended regex to match the conventional commit format.
# Arguments:
#   $1: commits - Multiline string of commit messages to filter
#   $2: type - Conventional commit type to filter for (e.g., "feat", "fix")
# Outputs:
#   Writes matching commit messages to stdout, one per line
# Returns:
#   0 always (empty output if no matches)
# Format Matched:
#   type(scope): message or type!: message
#######################################

_filter_commits_by_type() {
    local commits="$1"
    local type="$2"

    echo "$commits" | grep -E "^${type}(\(.*\))?!?: "
}

#######################################
# Generate formatted release notes from commit messages
# Analyzes commit messages to create structured release notes with sections
# for different commit types. Handles breaking changes with special prominence.
# Uses configuration to determine which commit types to include and their sections.
# Globals:
#   None (calls get_commit_types from config.sh)
# Arguments:
#   $1: commits - Multiline string of commit messages to process
# Outputs:
#   Writes formatted markdown release notes to stdout
# Returns:
#   0 always
# Output Format:
#   ### ⚠ BREAKING CHANGES (if any)
#   - Breaking change items
#   
#   ### Section Name
#   - Commit items
# Note:
#   Hidden commit types (configured with "hidden": true) are excluded
#######################################

get_notes() {
    local commits="$1"
    local output=""

    # Process breaking changes first with special formatting
    local breaking=$(echo "$commits" | grep -E "BREAKING CHANGE|!:")

    if [[ -n "$breaking" ]]; then
        echo "### ⚠ BREAKING CHANGES"
        echo ""
        echo "$breaking" \
            | sed -E 's/^BREAKING CHANGE:[[:space:]]*//' \
            | sed -E 's/^[a-z]+(\(.*\))?!?:[[:space:]]*//' \
            | sed 's/^/- /'
        echo ""
    fi

    # Process regular commit types based on configuration
    local types_json=$(get_commit_types)

    echo "$types_json" | jq -c '.[]' | while read -r block; do
        local type=$(echo "$block" | jq -r '.type')
        local section=$(echo "$block" | jq -r '.section')
        local hidden=$(echo "$block" | jq -r '.hidden')

        # Skip hidden commit types
        if [[ "$hidden" == "true" ]]; then
            continue
        fi

        # Find commits matching this type
        local matches=$(_filter_commits_by_type "$commits" "$type")

        if [[ -n "$matches" ]]; then
            echo "### $section"
            echo ""
            # Clean commit messages by removing type prefix and formatting as list
            echo "$matches" \
                | sed -E "s/^${type}(\(.*\))?!?:[[:space:]]*//" \
                | sed 's/^/- /'
            echo ""
        fi
    done
}

#######################################
# Write release notes to changelog file
# Creates or updates a changelog file with new release notes. Prepends new
# content to existing changelog to maintain reverse chronological order.
# Uses atomic file operations to prevent corruption.
# Globals:
#   None
# Arguments:
#   $1: version - Version tag for the release (e.g., "v1.2.3")
#   $2: notes - Formatted release notes content (markdown)
#   $3: output_file - Path to changelog file to update
# Outputs:
#   Progress information via log_info
# Returns:
#   0 on success, non-zero on file operation failure
# Side Effects:
#   - Creates or updates the specified changelog file
#   - Stages the changelog file for git commit
# File Format:
#   # v1.2.3 (YYYY-MM-DD)
#   
#   [release notes content]
#   
#   [previous changelog content...]
#######################################

write_changelog() {
    local version="$1"
    local notes="$2"
    local output_file="$3"
    local date=$(date +%Y-%m-%d)

    log_info "Writing changelog to $output_file"

    # Use temporary file for atomic update
    local temp_file="TEMP_CHANGELOG.md"

    # Create new release section header
    echo "# $version ($date)" > "$temp_file"
    echo "" >> "$temp_file"
    
    # Add release notes content
    echo "$notes" >> "$temp_file"
    echo "" >> "$temp_file"

    # Append existing changelog content if file exists
    if [[ -f "$output_file" ]]; then
        cat "$output_file" >> "$temp_file"
    fi

    # Atomically replace the changelog file
    mv "$temp_file" "$output_file"

    # Stage the updated changelog for commit
    git add "$output_file"
}
