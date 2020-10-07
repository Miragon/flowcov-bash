#!/bin/bash

# Copyright 2020 FlowSquad GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# For more info see:
# - our GitHub Repository:  https://github.com/FlowSquad/flowcov-bash
# - our Documentation:      https://docs.flowcov.io
# - our Website:            https://flowcov.io

# Set before release
version="0.3.0"

# Formatting constants
r="\033[0m"     # Reset
e="\033[1;31m"  # Error
l="\033[1;32m"  # Logo
w="\033[1;33m"  # Warning
h="\033[1;35m"  # Hint
v="\033[0;36m"  # Verbose
t="\033[1m"     # Title

# Required Parameters
FLOWCOV_API_KEY="${FLOWCOV_API_KEY:-}"
FLOWCOV_REPOSITORY_ID="${FLOWCOV_REPOSITORY_ID:-}"

# Build Type
FLOWCOV_CI_BUILD="${FLOWCOV_CI_BUILD:-}"
FLOWCOV_LOCAL_BUILD="${FLOWCOV_LOCAL_BUILD:-}"

# Commit Information
FLOWCOV_COMMIT_ID="${FLOWCOV_COMMIT_ID:-}"
FLOWCOV_COMMIT_MESSAGE="${FLOWCOV_COMMIT_MESSAGE:-}"
FLOWCOV_COMMIT_AUTHOR="${FLOWCOV_COMMIT_AUTHOR:-}"
FLOWCOV_BRANCH_NAME="${FLOWCOV_BRANCH_NAME:-}"
FLOWCOV_NO_GIT="${FLOWCOV_NO_GIT:-"false"}"
FLOWCOV_NO_AUTO_DETECTION="${FLOWCOV_NO_AUTO_DETECTION:-"false"}"

# Upload Parameters
FLOWCOV_SEARCH_DIR="${FLOWCOV_SEARCH_DIR:-"."}"
FLOWCOV_FAIL_ON_ERROR="${FLOWCOV_FAIL_ON_ERROR:-"false"}"
FLOWCOV_SKIP_EMPTY_UPLOAD="${FLOWCOV_SKIP_EMPTY_UPLOAD:-"false"}"
FLOWCOV_URL="${FLOWCOV_URL:-"https://app.flowcov.io"}"

# Debug parameters
FLOWCOV_DEBUG="${FLOWCOV_DEBUG:-"false"}"
FLOWCOV_VERBOSE="${FLOWCOV_VERBOSE:-"false"}"

# Shows the value of $1 using echo -e.
say() {
    echo -e "    $1"
}

# Prints header and version.
show_logo() {
    echo -e "$(
        cat << EOF
${l}
             ______ _                _____
            |  ____| |              / ____|  v$version
            | |__  | | _____      _| |     _____   __
            |  __| | |/ _ \ \ /\ / / |    / _ \ \ / /
            | |    | | (_) \ V  V /| |___| (_) \ V /
            |_|    |_|\___/ \_/\_/  \_____\___/ \_/
${r}

EOF
    )"
}

# Shows the help screen.
show_help() {
    echo -e "$(
        cat << EOF

                     ${t}FlowCov Bash v$version${r}

             Report uploading tool for FlowCov.io
           Documentation at https://docs.flowcov.io
    Contribute at https://github.com/FlowSquad/flowcov-bash


  ${t}Required Parameters${r}
  ${h}If one of these parameters is missing, the upload will fail.${r}

    ${t}-a KEY${r}      The API Key to use.
                    ${h}(or use)${r} --api-key KEY
                    ${h}(or set)${r} FLOWCOV_API_KEY=KEY

    ${t}-r ID${r}       The Repository to use.
                    ${h}(or use)${r} --repository-id ID
                    ${h}(or set)${r} FLOWCOV_REPOSITORY_ID=ID

  ${t}Build Type${r}
  ${h}If no build type is specified, auto-detection will be used to determine
  any supported CI provider. Setting this flag does not disable auto-detection
  for commit information.${r}

    ${t}-c${r}          Use Build Type CI.
                    ${h}(or use)${r} --ci

    ${t}-l${r}          Use Build Type Local.
                    ${h}(or use)${r} --local
                    ${h}(or use)${r} --no-ci ${w}[DEPRECATED]${r}

  ${t}Commit Information${r}
  ${h}By default, this information will be extracted from the environment
  variables set by your CI provider. If that is not possible, git will be
  queried for that information. Manual parameters always have precedence.${r}

    ${t}-ci SHA${r}     Override the commit id.
                    ${h}(or use)${r} --commit-id SHA
                    ${h}(or set)${r} FLOWCOV_COMMIT_ID=SHA

    ${t}-cm MSG${r}     Override the commit message.
                    ${h}(or use)${r} --commit-message MSG
                    ${h}(or set)${r} FLOWCOV_COMMIT_MESSAGE=MSG

    ${t}-ca NAME${r}    Override the commit author. Has the format "name <email>".
                    ${h}(or use)${r} --commit-author NAME
                    ${h}(or set)${r} FLOWCOV_COMMIT_AUTHOR=NAME

    ${t}-b NAME${r}     Override the branch name.
                    ${h}(or use)${r} --branch-name NAME
                    ${h}(or set)${r} FLOWCOV_BRANCH_NAME=NAME

    ${t}-xa${r}         Disable auto-detection of commit information.
                    ${h}(or use)${r} --no-auto-detection
                    ${h}(or set)${r} FLOWCOV_NO_AUTO_DETECTION=true

    ${t}-xg${r}         Disable git usage for auto-detection.
                    ${h}(or use)${r} --no-git
                    ${h}(or set)${r} FLOWCOV_NO_GIT=true

  ${t}Upload Parameters${r}
  ${h}Use these parameters to change the default behavior of the script. This
  is usually only required in certain situations.${r}

    ${t}-s DIR${r}      The directory to search for reports.
                    ${h}(or use)${r} --dir DIR
                    ${h}(or set)${r} FLOWCOV_SEARCH_DIR=DIR

    ${t}-f${r}          Fail the script if the upload fails.
                    ${h}(or use)${r} --fail-on-error
                    ${h}(or set)${r} FLOWCOV_FAIL_ON_ERROR=true

    ${t}-e${r}          Don't upload build if no reports were found.
                    ${h}(or use)${r} --skip-empty-upload
                    ${h}(or set)${r} FLOWCOV_SKIP_EMPTY_UPLOAD=true

    ${t}-u URL${r}      Override the target url for the upload. Required if you're
                using a managed or on-premise installation.
                    ${h}(or use)${r} --url URL
                    ${h}(or set)${r} FLOWCOV_URL=URL

  ${t}Help And Debug Options${r}
  ${h}Use these parameters to debug your command if it does not behave as expected.${r}

    ${t}-h${r}          Display this help and exit.
                    ${h}(or use)${r} --help

    ${t}-d${r}          Print the upload to console output instead of sending it to
                the server.
                    ${h}(or use)${r} --debug
                    ${h}(or set)${r} FLOWCOV_DEBUG=true

    ${t}-v${r}          Output additional log information for debugging.
                ${w}>> Attention: Argument must be passed as first argument!${r}
                    ${h}(or use)${r} --verbose
                    ${h}(or set)${r} FLOWCOV_VERBOSE=true

EOF
    )"
}

# Shows a progress title
title() {
    echo ""
    echo -e "${t}==> $1${r}"
}

# Shows the message in $1 if FLOWCOV_VERBOSE=true, else does nothing.
log() {
    if [ "$FLOWCOV_VERBOSE" = "true" ]; then
        say "${v}$1${r}"
    fi
}

# Shows the error passed as $1 and exit with code 1 if FLOWCOV_FAIL_ON_ERROR=true, else exit with code 0.
# If $2=true, help will be shown
throw_error() {
    if [ "$2" = "true" ]; then
        show_help
        say ""
        say ""
    fi

    say "${e}Error: $1${r}"
    say ""

    if [ "$FLOWCOV_FAIL_ON_ERROR" = "true" ]; then
        exit 1
    else
        exit 0
    fi
}

# Checks if $1 is empty or null and prints an error message "No argument specified for $2."
# if this is the case. Else does nothing.
require_parameter() {
    if [ "$1" = "" ]; then
        throw_error "No argument specified for $2." "true"
    fi
}

# Show logo header
show_logo

# Check if zero arguments were passed
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

title "Initializing..."

# If passed via environment variable, print verbose mode info
if [ "$FLOWCOV_VERBOSE" = "true" ]; then
    log "Using verbose mode"
fi

# Used to check if -v | --verbose is passed as first argument
is_first="true"
while test $# != 0; do
    log "Found parameter $1"
    case "$1" in
        -a | --api-key)
            require_parameter "$2" "$1"
            FLOWCOV_API_KEY=$2
            shift
            ;;
        -r | --repository-id)
            require_parameter "$2" "$1"
            FLOWCOV_REPOSITORY_ID=$2
            shift
            ;;
        -c | --ci)
            FLOWCOV_LOCAL_BUILD="false"
            FLOWCOV_CI_BUILD="true"
            ;;
        -l | --local | --no-ci)
            FLOWCOV_LOCAL_BUILD="true"
            FLOWCOV_CI_BUILD="false"
            ;;
        -ci | --commit-id)
            require_parameter "$2" "$1"
            FLOWCOV_COMMIT_ID=$2
            shift
            ;;
        -cm | --commit-message)
            require_parameter "$2" "$1"
            FLOWCOV_COMMIT_MESSAGE=$2
            shift
            ;;
        -ca | --commit-author)
            require_parameter "$2" "$1"
            FLOWCOV_COMMIT_AUTHOR=$2
            shift
            ;;
        -b | --branch-name)
            require_parameter "$2" "$1"
            FLOWCOV_BRANCH_NAME=$2
            shift
            ;;
        -xa | --no-auto-detection)
            FLOWCOV_NO_AUTO_DETECTION="true"
            ;;
        -xg | --no-git)
            FLOWCOV_NO_GIT="true"
            ;;
        -s | --dir)
            require_parameter "$2" "$1"
            FLOWCOV_SEARCH_DIR=$2
            shift
            ;;
        -f | --fail-on-error)
            FLOWCOV_FAIL_ON_ERROR="true"
            ;;
        -e | --skip-empty-upload)
            FLOWCOV_SKIP_EMPTY_UPLOAD="true"
            ;;
        -u | --url)
            require_parameter "$2" "$1"
            FLOWCOV_URL=$2
            shift
            ;;
        -h | --help)
            show_help
            exit 0
            ;;
        -d | --debug)
            FLOWCOV_DEBUG="true"
            ;;
        -v | --verbose)
            if [ "$is_first" = "false" ]; then
                throw_error "Argument $1 must be passed as first argument!" "true"
            fi;

            FLOWCOV_VERBOSE="true"
            # Log it extra so it does not get lost
            log "Using verbose mode"
            log "Found parameter $1"
            ;;
        *)
            # Fallback
            throw_error "Unrecognized parameter $1 passed!" "true"
            ;;
    esac
    is_first="false"
    shift
done

# Check if API key was provided
if [ -z "$FLOWCOV_API_KEY" ]; then
    throw_error "Your API key is required, but none was specified. You can find your API key in the repository settings." "true"
fi

# Check if repository ID was provided
if [ -z "$FLOWCOV_REPOSITORY_ID" ]; then
    throw_error "Your repository ID is required, but none was specified. You can find your repository ID in the repository settings." "true"
fi

title "Auto-detecting CI environment..."

# Check if auto-detection was disabled by flag or environment variable.
if [ "$FLOWCOV_NO_AUTO_DETECTION" = "true" ]; then
    say "Auto-detection of commit information was disabled."
else
    # Try to auto-detect environment and extract commit information from it.
    # Currently supported are:
    # - Jenkins
    # - Travis CI
    # - Codebuild CI
    # - CircleCI
    # - GitLab CI
    # - GitHub Actions

    # Detection marker
    detected="false"

    # Check for Jenkins
    if [ -n "$JENKINS_URL" ]; then
        say "Jenkins CI detected."
        detected="true"

        # Extract commit id
        [ -z "$FLOWCOV_COMMIT_ID" ] \
            && [ -n "$GIT_COMMIT" ] \
            && FLOWCOV_COMMIT_ID="$GIT_COMMIT" \
            && log "Extracted commit id:       '$FLOWCOV_COMMIT_ID'"

        # Extract branch name from...
        # 1. $GIT_BRANCH
        # 2. $BRANCH_NAME

        [ -z "$FLOWCOV_BRANCH_NAME" ] \
            && [ -n "$GIT_BRANCH" ] \
            && FLOWCOV_BRANCH_NAME="$GIT_BRANCH" \
            && log "Extracted branch name:     '$FLOWCOV_BRANCH_NAME'"

        [ -z "$FLOWCOV_BRANCH_NAME" ] \
            && [ -n "$BRANCH_NAME" ] \
            && FLOWCOV_BRANCH_NAME="$BRANCH_NAME" \
            && log "Extracted branch name:     '$FLOWCOV_BRANCH_NAME'"

    # Check for Travis CI
    elif [ -n "$TRAVIS" ]; then
        say "Travis CI detected."
        detected="true"

        # Extract commit id
        [ -z "$FLOWCOV_COMMIT_ID" ] \
            && [ -n "$TRAVIS_COMMIT" ] \
            && FLOWCOV_COMMIT_ID="$TRAVIS_COMMIT" \
            && log "Extracted commit id:       '$FLOWCOV_COMMIT_ID'"

        # Extract branch name
        # If this is a pull request, the source branch is available from
        # $TRAVIS_PULL_REQUEST_BRANCH, else from $TRAVIS_BRANCH
        [ -z "$FLOWCOV_BRANCH_NAME" ] \
            && [ -n "${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}" ] \
            && FLOWCOV_BRANCH_NAME="${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}" \
            && log "Extracted branch name:     '$FLOWCOV_BRANCH_NAME'"

        # Extract commit message
        [ -z "$FLOWCOV_COMMIT_MESSAGE" ] \
            && [ -n "$TRAVIS_COMMIT_MESSAGE" ] \
            && FLOWCOV_COMMIT_MESSAGE="$TRAVIS_COMMIT_MESSAGE" \
            && log "Extracted commit message:  '$FLOWCOV_COMMIT_MESSAGE'"

    # Check for Codebuild CI
    elif [ -n "$CODEBUILD_BUILD_ID" ]; then
        say "Codebuild CI detected."
        detected="true"

        # Extract commit id
        [ -z "$FLOWCOV_COMMIT_ID" ] \
            && [ -n "$CODEBUILD_RESOLVED_SOURCE_VERSION" ] \
            && FLOWCOV_COMMIT_ID="$CODEBUILD_RESOLVED_SOURCE_VERSION" \
            && log "Extracted commit id:       '$FLOWCOV_COMMIT_ID'"

        # Extract branch name and cut of refs/heads/ prefix
        [ -z "$FLOWCOV_BRANCH_NAME" ] \
            && [ -n "$CODEBUILD_WEBHOOK_HEAD_REF" ] \
            && FLOWCOV_BRANCH_NAME="$(echo "$CODEBUILD_WEBHOOK_HEAD_REF" | sed 's/^refs\/heads\///')" \
            && log "Extracted branch name:     '$FLOWCOV_BRANCH_NAME'"

    # Check for CircleCI
    elif [ -n "$CIRCLECI" ]; then
        say "CircleCI detected."
        detected="true"

        # Extract commit id
        [ -z "$FLOWCOV_COMMIT_ID" ] \
            && [ -n "$CIRCLE_SHA1" ] \
            && FLOWCOV_COMMIT_ID="$CIRCLE_SHA1" \
            && log "Extracted commit id:       '$FLOWCOV_COMMIT_ID'"

        # Extract branch name
        [ -z "$FLOWCOV_BRANCH_NAME" ] \
            && [ -n "$CIRCLE_BRANCH" ] \
            && FLOWCOV_BRANCH_NAME="$CIRCLE_BRANCH" \
            && log "Extracted branch name:     '$FLOWCOV_BRANCH_NAME'"

        # Not extracting the CIRCLE_USERNAME variable because it is not necessarily
        # the commit author, but the user who triggered the build

    # Check for GitLab CI
    elif [ -n "$GITLAB_CI" ]; then
        say "GitLab CI detected."
        detected="true"

        # Extract commit id
        [ -z "$FLOWCOV_COMMIT_ID" ] \
            && [ -n "$CI_COMMIT_SHORT_SHA" ] \
            && FLOWCOV_COMMIT_ID="$CI_COMMIT_SHORT_SHA" \
            && log "Extracted commit id:       '$FLOWCOV_COMMIT_ID'"

        # Extract branch name
        [ -z "$FLOWCOV_BRANCH_NAME" ] \
            && [ -n "$CI_COMMIT_BRANCH" ] \
            && FLOWCOV_BRANCH_NAME="$CI_COMMIT_BRANCH" \
            && log "Extracted branch name:     '$FLOWCOV_BRANCH_NAME'"

        # Extract commit message
        [ -z "$FLOWCOV_COMMIT_MESSAGE" ] \
            && [ -n "$CI_COMMIT_MESSAGE" ] \
            && FLOWCOV_COMMIT_MESSAGE="$CI_COMMIT_MESSAGE" \
            && log "Extracted commit message:  '$FLOWCOV_COMMIT_MESSAGE'"

    # Check for GitHub Actions
    elif [ -n "$GITHUB_ACTIONS" ]; then
        say "GitHub Actions detected."
        detected="true"

        # Extract commit id
        [ -z "$FLOWCOV_COMMIT_ID" ] \
            && [ -n "$GITHUB_SHA" ] \
            && FLOWCOV_COMMIT_ID="$GITHUB_SHA" \
            && log "Extracted commit id:       '$FLOWCOV_COMMIT_ID'"

        # Extract branch name and cut of refs/heads/ prefix
        [ -z "$FLOWCOV_BRANCH_NAME" ] \
            && [ -n "$GITHUB_REF" ] \
            && FLOWCOV_BRANCH_NAME="$(echo "$GITHUB_REF" | sed 's/^refs\/heads\///')" \
            && log "Extracted branch name:     '$FLOWCOV_BRANCH_NAME'"
    fi

    if [ "$detected" = "false" ]; then
        say "Could not detect CI environment. Using build type local."
    fi

    # If any commit information is missing, try to extract it from git
    if [ -z "$FLOWCOV_COMMIT_ID" ] \
        || [ -z "$FLOWCOV_COMMIT_MESSAGE" ] \
        || [ -z "$FLOWCOV_COMMIT_AUTHOR" ] \
        || [ -z "$FLOWCOV_BRANCH_NAME" ]; then
        log "Commit information missing, trying to extract it from git"
        # Add commit information from git if not disabled via environment variable or flag.
        if [ "$FLOWCOV_NO_GIT" != "true" ]; then
            # Check if git is available
            git --version > /dev/null 2>&1
            git_available=$?

            if [ $git_available -eq 0 ]; then
                # Check if current directory is a git directory
                if [ ! -d .git ]; then
                    say "Current directory ($(pwd)) is not a git repository. Not adding missing commit information."
                else
                    # Add missing commit information by calling git
                    say "Adding missing commit information from git."
                    [ -z "$FLOWCOV_COMMIT_ID" ] \
                        && FLOWCOV_COMMIT_ID=$(git rev-parse --short HEAD 2> /dev/null) \
                        && log "Extracted commit id:       '$FLOWCOV_COMMIT_ID'"

                    [ -z "$FLOWCOV_COMMIT_MESSAGE" ] \
                        && FLOWCOV_COMMIT_MESSAGE=$(git log --format=%B -n 1 "$FLOWCOV_COMMIT_ID" 2> /dev/null) \
                        && log "Extracted commit message:  '$FLOWCOV_COMMIT_MESSAGE'"

                    [ -z "$FLOWCOV_COMMIT_AUTHOR" ] \
                        && FLOWCOV_COMMIT_AUTHOR=$(git show -s --format='%an <%ae>' "$FLOWCOV_COMMIT_ID" 2> /dev/null) \
                        && log "Extracted commit author:   '$FLOWCOV_COMMIT_AUTHOR'"

                    [ -z "$FLOWCOV_BRANCH_NAME" ] \
                        && FLOWCOV_BRANCH_NAME=$(git rev-parse --abbrev-ref --symbolic-full-name @\{u\} 2> /dev/null) \
                        && FLOWCOV_BRANCH_NAME=${FLOWCOV_BRANCH_NAME#*/} \
                        && log "Extracted branch name:     '$FLOWCOV_BRANCH_NAME'"
                fi
            else
                say "Git is not available on path. Not adding missing commit information."
            fi
        else
            log "Commit information extraction from git is disabled."
        fi
    fi

    if [ -z "$FLOWCOV_CI_BUILD" ] && [ -z "$FLOWCOV_LOCAL_BUILD" ]; then
        if [ "$detected" = "true" ]; then
            FLOWCOV_CI_BUILD="true"
            FLOWCOV_LOCAL_BUILD="false"
        else
            FLOWCOV_CI_BUILD="false"
            FLOWCOV_LOCAL_BUILD="true"
        fi
    fi
fi

title "Gathering reports..."

# Check if search directory exists
if [ ! -d "$FLOWCOV_SEARCH_DIR" ]; then
    throw_error "Search directory $FLOWCOV_SEARCH_DIR does not exist!"
fi

# Notify user about search dir
say "Searching in directory $(cd "$FLOWCOV_SEARCH_DIR" && pwd)."

# Print all files in verbose mode
if [ "$FLOWCOV_VERBOSE" = "true" ]; then
    file_count=0
    while read -r file; do log "Found $file"; (( file_count+=1 )); done < \
        <(find "${FLOWCOV_SEARCH_DIR}" -name 'flowCovReport.json' 2> /dev/null)
    log "Found $file_count file(s)"
fi

# Find all matching files in all subdirectories, then join their content with a comma as separator
reports=$(find "${FLOWCOV_SEARCH_DIR}" -name 'flowCovReport.json' -print0 2> /dev/null \
    | xargs -I{} -0 sh -c '{ cat {}; echo ,; }')

# If no reports were found and FLOWCOV_SKIP_EMPTY_UPLOAD="true", exit early
if [ "$FLOWCOV_SKIP_EMPTY_UPLOAD" = "true" ] && [ -z "$reports" ]; then
    say "No reports found in search directory. Skipping upload." && exit 0
fi

# Remove the last comma by reversing the string, removing the first char, and reversing it again
# If we put $reports in quotes, it will break the JSON string -> TODO: could this become a problem?
# shellcheck disable=SC2086
reports=$(echo $reports | rev | cut -c 2- | rev)

# Escape all parameters (escape double quotes)
[ -n "$FLOWCOV_COMMIT_ID" ] && FLOWCOV_COMMIT_ID=${FLOWCOV_COMMIT_ID//"\""/"\\\""}
[ -n "$FLOWCOV_BRANCH_NAME" ] && FLOWCOV_BRANCH_NAME=${FLOWCOV_BRANCH_NAME//"\""/"\\\""}
[ -n "$FLOWCOV_COMMIT_MESSAGE" ] && FLOWCOV_COMMIT_MESSAGE=${FLOWCOV_COMMIT_MESSAGE//"\""/"\\\""}
[ -n "$FLOWCOV_COMMIT_AUTHOR" ] && FLOWCOV_COMMIT_AUTHOR=${FLOWCOV_COMMIT_AUTHOR//"\""/"\\\""}

# Create the json array with the now comma-separated list of reports
json="{"

# Add all optional information
[ -n "$FLOWCOV_COMMIT_ID" ] && json="$json\"commitId\":\"$FLOWCOV_COMMIT_ID\","
[ -n "$FLOWCOV_BRANCH_NAME" ] && json="$json\"branchName\":\"$FLOWCOV_BRANCH_NAME\","
[ -n "$FLOWCOV_COMMIT_MESSAGE" ] && json="$json\"commitMessage\":\"$FLOWCOV_COMMIT_MESSAGE\","
[ -n "$FLOWCOV_COMMIT_AUTHOR" ] && json="$json\"commitAuthor\":\"$FLOWCOV_COMMIT_AUTHOR\","

# Evaluate build type to is_ci boolean. We use two variables
# because we might want to pass more information in the future.
if [ "$FLOWCOV_LOCAL_BUILD" = "true" ] && [ "$FLOWCOV_CI_BUILD" = "true" ]; then
    is_ci="true"
else
    is_ci="false"
fi

# Add all required information
json="$json\"repositoryId\":\"$FLOWCOV_REPOSITORY_ID\","
json="$json\"ci\":$is_ci,"
json="$json\"data\":[$reports]}"

# If debug is enabled, just print out the request body
if [ "$FLOWCOV_DEBUG" = "true" ]; then
    # If jq is installed, use it
    if hash jq 2> /dev/null; then
        echo "$json" | jq --color-output
    # Else just print it to stdout
    else
        echo "$json"
    fi
    exit 0
fi

title "Uploading report..."

# Create URL
url="$FLOWCOV_URL/api/v0/build/upload?apiKey=$FLOWCOV_API_KEY"

# Log URL, but don't print the API key
log "Using URL ${url/$FLOWCOV_API_KEY/***}"

# Build additional args that are passed to curl
curl_args=()

if [ "$FLOWCOV_VERBOSE" = "true" ]; then
    curl_args+=("-v")
fi;

# Push them to the server
result=$(curl \
    --write-out "%{http_code}" \
    --silent \
    --output /dev/null \
    "${curl_args[@]}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$json" \
    "$url")

# Check if response code was 200
if [ "$result" -eq 200 ]; then
    say "Successfully uploaded report."
    title "Done."
    say ""
    exit 0
elif [ "$FLOWCOV_FAIL_ON_ERROR" = "true" ]; then
    throw_error "Failed to upload report with status code $result."
else
    say "${e}Failed to upload report with status code $result.${r}"
    say ""
    exit 0
fi
