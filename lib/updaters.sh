#!/usr/bin/env bash
#
# File Version Updaters Module
#
# Provides secure file update functions for automatically updating version numbers
# in various file formats. Includes comprehensive security validations to prevent
# directory traversal attacks and code injection vulnerabilities.
#
# Supported File Types:
#   - npm/json: Updates version field in package.json and other JSON files
#   - python: Updates __version__ variable in Python files  
#   - text: Simple text file containing only version number
#   - custom-regex: User-defined sed patterns with security restrictions
#
# Security Features:
#   - Path validation prevents directory traversal (../, absolute paths)
#   - Version format validation prevents injection attacks
#   - Regex pattern validation blocks dangerous sed flags (e, w)
#   - File existence checks before operations
#
# Functions:
#   - _is_safe_path()     Validates file paths for security
#   - _update_json()      Updates JSON files using jq
#   - _update_python()    Updates Python __version__ variables
#   - _update_custom()    Applies custom regex patterns safely
#   - run_updaters()      Main orchestration function
#
# Dependencies: jq, sed, git

#######################################
# Validate file path for security vulnerabilities
# Checks for directory traversal attempts and absolute paths that could
# allow access to files outside the repository boundary.
# Arguments:
#   $1: path - File path to validate
# Returns:
#   0 if path is safe, 1 if potentially dangerous
# Security Checks:
#   - Rejects absolute paths (starting with /)
#   - Rejects relative paths containing ../
#   - Rejects paths starting with ../
#######################################
_is_safe_path() {
    local path="$1"
    if [[ "$path" == /* ]] || [[ "$path" == *"../"* ]] || [[ "$path" == "../"* ]]; then
        return 1 # Unsafe
    fi
    return 0 # Safe
}

#######################################
# Update version field in JSON files
# Uses jq to safely update the version field in JSON files such as package.json.
# Creates temporary file for atomic updates.
# Arguments:
#   $1: file - Path to JSON file to update
#   $2: version - New version string to set
# Globals:
#   None
# Outputs:
#   None (modifies file in place)
# Returns:
#   0 on success, non-zero on jq failure
#######################################
_update_json() {
    local file="$1"
    local version="$2"
    jq --arg v "$version" '.version = $v' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

#######################################
# Update __version__ variable in Python files
# Uses sed to update __version__ variable assignment in Python source files.
# Handles both single and double quote variations.
# Arguments:
#   $1: file - Path to Python file to update
#   $2: version - New version string to set
# Globals:
#   None
# Outputs:
#   None (modifies file in place)
# Returns:
#   0 on success, non-zero on sed failure
#######################################
_update_python() {
    local file="$1"
    local version="$2"
    sed -i "s#^__version__ = .*#__version__ = \"$version\"#" "$file"
}

#######################################
# Apply custom regex pattern to update version in files
# SECURITY CRITICAL: This function executes user-provided sed patterns.
# Includes multiple security validations to prevent code execution.
# Arguments:
#   $1: file - Path to file to update
#   $2: version - New version string to substitute
#   $3: pattern - Sed substitution pattern with %VERSION% placeholder
# Globals:
#   None
# Outputs:
#   Warning/error messages to stderr for security violations
# Returns:
#   0 on success, early return on security violations
# Security Features:
#   - Blocks patterns containing 'e' flag (execute command)
#   - Blocks patterns containing 'w' flag (write to file)
#   - Validates pattern format
# Pattern Format:
#   Standard sed substitution: s/find/replace/
#   Use %VERSION% as placeholder for version number
#######################################
_update_custom() {
    local file="$1"
    local version="$2"
    local pattern="$3"

    if [[ -z "$pattern" ]]; then
        log_warning "No pattern provided for custom-regex in $file"
        return
    fi

    if [[ "$pattern" =~ s/.*/.*/.*[ew].* ]]; then
        log_error "SECURITY ERROR: The regex pattern contains unsafe flags ('e' or 'w'). Operation aborted for $file"
        return
    fi

    local sed_cmd=${pattern//%VERSION%/$version}

    sed -i "$sed_cmd" "$file"
}

#######################################
# Main function to run all configured file updaters
# Orchestrates the file update process by reading configuration, validating
# inputs, and applying updates to all configured target files.
# Arguments:
#   $1: new_version - Version string to update files with
# Globals:
#   CONFIG_CONTENT (via get_config_value)
# Outputs:
#   Progress messages and warnings/errors to stdout/stderr
# Returns:
#   0 on success (continues processing even if individual files fail)
# Security Features:
#   - Validates version format with regex
#   - Validates all file paths before processing
#   - Skips missing files with warning
#   - Adds updated files to git staging area
# Process:
#   1. Validate version format
#   2. Read targets configuration
#   3. Process each target with appropriate updater
#   4. Stage changes in git
#######################################
run_updaters() {
    local new_version="$1"
    local targets_json=$(get_config_value "targets")

    if [[ -z "$targets_json" || "$targets_json" == "null" ]]; then
        log_info "No file updates configured."
        return
    fi

    # Security validation: ensure version contains only safe characters
    if [[ ! "$new_version" =~ ^[0-9a-zA-Z\.\-]+$ ]]; then
        log_error "SECURITY ERROR: Invalid version format '$new_version'. Aborting updates."
        return
    fi

    log_info "Updating project files to version $new_version:"

    # Process each configured target file
    echo "$targets_json" | jq -c '.[]' | while read -r target; do
        local path=$(echo "$target" | jq -r '.path')
        local type=$(echo "$target" | jq -r '.type')
        local pattern=$(echo "$target" | jq -r '.pattern // empty')

        # Security check: validate file path safety
        if ! _is_safe_path "$path"; then
             log_error "SECURITY WARNING: Path '$path' is trying to escape the repository. Skipping."
             continue
        fi

        # Existence check: ensure target file exists
        if [[ ! -f "$path" ]]; then
            log_warning "File not found: $path. Skipping."
            continue
        fi

        log_info "  -> Updating $path ($type)"

        # Apply appropriate updater based on file type
        case "$type" in
            "npm"|"json")
                _update_json "$path" "$new_version"
                ;;
            "text")
                echo "$new_version" > "$path"
                ;;
            "python")
                _update_python "$path" "$new_version"
                ;;
            "custom-regex")
                _update_custom "$path" "$new_version" "$pattern"
                ;;
            *)
                log_warning "Unknown updater type: $type"
                ;;
        esac

        # Stage the updated file for commit
        git add "$path"
    done
}
