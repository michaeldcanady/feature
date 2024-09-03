#!/bin/bash

# Constants
BASE_URL="https://api.github.com/repos/bitwarden/clients/releases"
TAGS_URL="$BASE_URL/tags"
TAG_PREFIX="cli-v"
VERSION_REGEX="^[0-9]{4}\.[0-9]+\.[0-9]+$"
VERSION_TAG_REGEX="^${TAG_PREFIX}[0-9]{4}\.[0-9]+\.[0-9]+$"
STATUS_OK=200
STATUS_NOT_FOUND=404
EXECUTABLE_NAME="bw"
INSTALL_DIR="/usr/local/bin/"
DOWNLOAD_DIR="/tmp"
EXTRACT_DIR="/tmp"

# Functions
check_dependency() {
    local dependency=$1
    if ! command -v "$dependency" &> /dev/null; then
        echo "Error: $dependency could not be found. Please install it to proceed."
        exit 1
    fi
}

fetch_latest_version() {
    curl -s "$BASE_URL" | jq -r "[.[] | select(.tag_name | startswith(\"${TAG_PREFIX}\")) | .tag_name] | sort | last"
}

validate_version_format() {
    local version=$1
    if [[ ! $version =~ $VERSION_REGEX ]]; then
        echo "Error: Invalid version format (${version}). Please use the format YYYY.M.D (e.g., 2024.8.1)."
        exit 1
    fi
}

get_release_url() {
    local version=$1
    echo "$TAGS_URL/$version"
}

check_release_exists() {
    local release_url=$1
    local status_code
    status_code=$(curl -I "$release_url" 2>/dev/null | head -n 1 | cut -d$' ' -f2)
    if [ "$status_code" -eq $STATUS_NOT_FOUND ]; then
        echo "Error: Release version \"$version\" not found."
        exit 1
    fi
}

get_cli_url() {
    local release_url=$1
    local file_name_regex="${EXECUTABLE_NAME}-${os}-.*.zip"
    curl -s "$release_url" | jq -r ".assets[] | select(.name | test(\"${file_name_regex}\")) | .browser_download_url"
}

download_and_extract() {
    local cli_url=$1
    local zip_file
    local extracted_dir

    curl -LO --create-dirs --output-dir "$DOWNLOAD_DIR" "$cli_url"
    zip_filename="$(basename "$cli_url")"
    zip_file="${DOWNLOAD_DIR}/${zip_filename}"
    echo "Downloaded $zip_file."

    extracted_dir="${EXTRACT_DIR}/${zip_filename%.*}"
    unzip "$zip_file" -d "$extracted_dir"
    echo "Unzipped $extracted_dir."

    chmod +x "$extracted_dir/$EXECUTABLE_NAME"
    echo "Made the executable file executable."

    sudo mv "$extracted_dir/$EXECUTABLE_NAME" "$INSTALL_DIR"
    echo "Installed the executable."

    rm -rf "$extracted_dir"
    rm "$zip_file"
    echo "Cleaned up files."
}

# Main script
version=$VERSION
os=$OS

check_dependency "jq"
check_dependency "unzip"

if [ -z "$os" ]; then
    echo "Error: OS must be specified."
    exit 1
fi

if [ -z "$version" ]; then
    echo "Error: VERSION must be specified."
    exit 1
fi

# Convert version to lowercase for case-insensitive comparison
version=$(echo "$version" | tr '[:upper:]' '[:lower:]')

if [ "$version" == "latest" ]; then
    echo "Fetching the highest cli version..."
    version=$(fetch_latest_version)
    if [ -z "$version" ]; then
        echo "Error: No cli releases found."
        exit 1
    fi
fi

if [[ $version =~ $VERSION_TAG_REGEX ]]; then
    version="${version/$TAG_PREFIX/""}"
fi

validate_version_format "$version"

echo "Downloading cli release v$version for $os..."
local release_url
release_url=$(get_release_url "${TAG_PREFIX}${version}")
check_release_exists "$release_url"

local cli_url
cli_url=$(get_cli_url "$release_url")
if [ -z "$cli_url" ]; then
    echo "Error: Download URL not found."
    exit 1
fi

download_and_extract "$cli_url"