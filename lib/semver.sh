#!/usr/bin/env bash
#
# Semantic Versioning Module
#
# Provides functions for semantic version calculation and bump type determination
# based on conventional commit analysis. Follows semver.org specifications.
# Analyzes commit messages to determine appropriate version increments and
# calculates next version numbers according to semantic versioning rules.
#
# Functions:
#   - get_bump_type()           Analyzes commits to determine version bump level
#   - calculate_next_version()  Calculates next version from current + bump type
#
# Dependencies:
#   - jq (for JSON parsing of commit type configuration)
#   - config.sh (for get_commit_types function)
#   - grep (for pattern matching in commit messages)

# =========================================
#           SEMANTIC VERSIONING
# =========================================

#######################################
# Determine version bump type from commit messages
# Analyzes commit messages according to conventional commit standards to determine
# the appropriate semantic version bump. Checks for breaking changes first,
# then examines commit types based on configuration.
# Globals:
#   None (calls get_commit_types from config.sh)
# Arguments:
#   $1: commits - Multiline string of commit messages to analyze
# Outputs:
#   Writes bump type to stdout: "major", "minor", "patch", or "none"
# Returns:
#   0 always
# Priority Order:
#   1. BREAKING CHANGE or "!" syntax -> major
#   2. Configured major types -> major
#   3. Configured minor types -> minor  
#   4. Configured patch types -> patch
#   5. Default -> none
#######################################
get_bump_type() {
    local commits="$1"          # Multiline string of commit messages

    if echo "$commits" | grep -qE 'BREAKING CHANGE|^[a-z]+(\(.+\))?!:'; then
        echo "major"
        return 0
    fi

    local types_config=$(get_commit_types)

    #######################################
    # Check if commits contain specified bump level types
    # Helper function that examines commit messages for specific commit types
    # that correspond to a given version bump level.
    # Local Arguments:
    #   $1: level - The bump level to check for (major|minor|patch)
    # Local Returns:
    #   0 if commits contain types for this level, 1 otherwise
    #######################################
    check_bump_level() {
        local level="$1"

        local types_to_check=$(echo "$types_config" | jq -r --arg lvl "$level" '.[] | select(.bump == $lvl) | .type')

        if [ -z "$types_to_check" ]; then
            return 1
        fi

        local regex_pattern="^($(echo "$types_to_check" | tr '\n' '|' | sed 's/|$//'))(\(.+\))?:"

        if echo "$commits" | grep -qE "$regex_pattern"; then
            return 0
        else
            return 1
        fi
    }

    if check_bump_level "major"; then
        echo "major"
        return 0
    fi

    if check_bump_level "minor"; then
        echo "minor"
        return 0
    fi

    if check_bump_level "patch"; then
        echo "patch"
        return 0
    fi

    echo "none"
}

#######################################
# Calculate next semantic version based on current version and bump type
# Takes a current version string and bump type, then calculates the next
# version according to semantic versioning rules. Handles version strings
# with or without 'v' prefix and missing components.
# Globals:
#   None
# Arguments:
#   $1: current_version - Current version string (e.g., "v1.2.3" or "1.2.3")
#   $2: bump_type - Type of version bump (major|minor|patch|none)
# Outputs:
#   Writes new version number to stdout (without 'v' prefix)
# Returns:
#   0 always
# Examples:
#   calculate_next_version "v1.2.3" "minor"  # outputs: 1.3.0
#   calculate_next_version "1.0.0" "major"   # outputs: 2.0.0
#   calculate_next_version "0.1" "patch"     # outputs: 0.1.1
# Version Bump Rules:
#   - major: X+1.0.0 (resets minor and patch to 0)
#   - minor: X.Y+1.0 (resets patch to 0)
#   - patch: X.Y.Z+1
#   - none: X.Y.Z (no change)
#######################################
calculate_next_version() {
    local current_version="$1"  # e.g., "v1.2.3"
    local bump_type="$2"        # e.g., "major", "minor", "patch", "none"

    # Parse version components, handling 'v' prefix and missing components
    IFS='.' read -r major minor patch <<< "$current_version"

    # Remove 'v' prefix if present
    major=${major#v}

    # Set default values for missing components
    major=${major:-0}
    minor=${minor:-0}
    patch=${patch:-0}

    log_debug "Parsed version components - major: $major, minor: $minor, patch: $patch"

    # Apply version bump according to semantic versioning rules
    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        none)
            # No version change
            ;;
        *)
            log_error "Unknown bump type: $bump_type"
            ;;
    esac

    echo "${major}.${minor}.${patch}"
}
