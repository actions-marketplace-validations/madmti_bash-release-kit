#!/usr/bin/env bash
#
# Logging Module
#
# Provides colored logging functions with timestamps for consistent output formatting.
# Supports different log levels: INFO, SUCCESS, WARNING, ERROR, DEBUG, and FATAL.
# All functions automatically include timestamps and appropriate color coding.
#
# Functions:
#   - get_timestamp()    Returns current timestamp in YYYY-MM-DD HH:MM:SS format
#   - log_info()        Standard informational messages (blue)
#   - log_success()     Success messages (green)  
#   - log_warning()     Warning messages to stderr (yellow)
#   - log_error()       Error messages to stderr (red)
#   - log_debug()       Debug messages to stderr (gray, controlled by DEBUG env var)
#   - log_fatal()       Fatal error with exit (red, terminates script)
#
# Environment Variables:
#   DEBUG - When set to "true", enables debug message output
#
# Dependencies: date command

# =========================================
#                   COLORS
# =========================================

readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly GRAY='\033[0;37m'
readonly NC='\033[0m'

# =========================================
#               LOG FUNCTIONS
# =========================================

#######################################
# Get current timestamp for logging
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes timestamp to stdout in format: YYYY-MM-DD HH:MM:SS
# Returns:
#   0 always
#######################################
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

#######################################
# Log informational message with blue color
# Globals:
#   BLUE, NC (color constants)
# Arguments:
#   $1: message - The message to log
# Outputs:
#   Writes formatted message to stdout
# Returns:
#   0 always
#######################################
log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $(get_timestamp) - $message"
}

#######################################
# Log success message with green color
# Globals:
#   GREEN, NC (color constants)
# Arguments:
#   $1: message - The success message to log
# Outputs:
#   Writes formatted message to stdout
# Returns:
#   0 always
#######################################
log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $(get_timestamp) - $message"
}

#######################################
# Log warning message with yellow color to stderr
# Globals:
#   YELLOW, NC (color constants)
# Arguments:
#   $1: message - The warning message to log
# Outputs:
#   Writes formatted message to stderr
# Returns:
#   0 always
#######################################
log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $(get_timestamp) - $message" >&2
}

#######################################
# Log error message with red color to stderr
# Globals:
#   RED, NC (color constants)
# Arguments:
#   $1: message - The error message to log
# Outputs:
#   Writes formatted message to stderr
# Returns:
#   0 always
#######################################
log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $(get_timestamp) - $message" >&2
}

#######################################
# Log debug message with gray color to stderr (conditional)
# Only outputs when DEBUG environment variable is set to "true"
# Globals:
#   GRAY, NC (color constants)
#   DEBUG (environment variable)
# Arguments:
#   $1: message - The debug message to log
# Outputs:
#   Writes formatted message to stderr if DEBUG=true
# Returns:
#   0 always
#######################################
log_debug() {
    local message="$1"
    if [[ "${DEBUG:-}" == "true" ]]; then
        echo -e "${GRAY}[DEBUG]${NC} $(get_timestamp) - $message" >&2
    fi
}

#######################################
# Log fatal error message and exit script
# Logs error message and terminates script execution
# Globals:
#   None (calls log_error which uses color constants)
# Arguments:
#   $1: message - The fatal error message to log
#   $2: exit_code - Exit code (optional, default: 1)
# Outputs:
#   Writes formatted error message to stderr
# Returns:
#   Does not return (script exits)
#######################################
log_fatal() {
    local message="$1"
    local exit_code="${2:-1}"
    log_error "$message"
    exit "$exit_code"
}
