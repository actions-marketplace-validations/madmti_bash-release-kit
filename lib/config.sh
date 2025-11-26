#!/usr/bin/env bash

# =========================================
#               CONFIGURATION
# =========================================
readonly CONFIG_FILE="${CONFIG_FILE_PATH:-release-config.json}"
readonly DEFAULT_CONFIG='{"github": {"active": true}}'

setup_config() {
    if ! command -v jq &> /dev/null; then
        log_fatal "Command \"jq\" not found. It is required for configuration parsing."
    fi

    if [[ -f "$CONFIG_FILE" ]]; then
        CONFIG_CONTENT=$(< "$CONFIG_FILE")
    else
        log_warning "Config file $CONFIG_FILE not found. Using default configuration."
        CONFIG_CONTENT="$DEFAULT_CONFIG"
    fi
}

get_config_value() {
    local key="$1"
    echo "$CONFIG_CONTENT" | jq -r --arg path "$key" 'getpath($path | split(".")) // empty'
}

check_github_active() {
    local github_exists=$(get_config_value "github")

    if [[ -n "$github_exists" && "$github_exists" != "null" ]]; then
        local is_active=$(get_config_value "github.active")

        if [[ "$is_active" == "true" ]]; then
            return 0 # True
        fi
    fi

    return 1 # False
}
