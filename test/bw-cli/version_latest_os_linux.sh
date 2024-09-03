#!/bin/bash

# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'color' feature with "favorite": "gold" option.

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Get latest release
BASE_URL="https://api.github.com/repos/bitwarden/clients/releases"
TAG_PREFIX="cli-v"
version=$(curl -s "$BASE_URL" | jq -r "[.[] | select(.tag_name | startswith(\"${TAG_PREFIX}\")) | .tag_name] | sort | last")
version="${version/$TAG_PREFIX/""}"
# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "execute command" bash -c "bw --version | grep '${version}'"

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
