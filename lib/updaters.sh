#!/usr/bin/env bash

_is_safe_path() {
    local path="$1"
    if [[ "$path" == /* ]] || [[ "$path" == *"../"* ]] || [[ "$path" == "../"* ]]; then
        return 1 # Unsafe
    fi
    return 0 # Safe
}

_update_json() {
    local file="$1"
    local version="$2"
    jq --arg v "$version" '.version = $v' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

_update_python() {
    local file="$1"
    local version="$2"
    sed -i "s#^__version__ = .*#__version__ = \"$version\"#" "$file"
}

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

run_updaters() {
    local new_version="$1"
    local targets_json=$(get_config_value "targets")

    if [[ -z "$targets_json" || "$targets_json" == "null" ]]; then
        log_info "No file updates configured."
        return
    fi

    if [[ ! "$new_version" =~ ^[0-9a-zA-Z\.\-]+$ ]]; then
        log_error "SECURITY ERROR: Invalid version format '$new_version'. Aborting updates."
        return
    fi

    log_info "Updating project files to version $new_version:"

    echo "$targets_json" | jq -c '.[]' | while read -r target; do
        local path=$(echo "$target" | jq -r '.path')
        local type=$(echo "$target" | jq -r '.type')
        local pattern=$(echo "$target" | jq -r '.pattern // empty')

        if ! _is_safe_path "$path"; then
             log_error "SECURITY WARNING: Path '$path' is trying to escape the repository. Skipping."
             continue
        fi

        if [[ ! -f "$path" ]]; then
            log_warning "File not found: $path. Skipping."
            continue
        fi

        log_info "  -> Updating $path ($type)"

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

        git add "$path"
    done
}
