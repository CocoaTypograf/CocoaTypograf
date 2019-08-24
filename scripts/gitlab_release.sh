#!/bin/bash

# logging

__COLOR_NONE="\033[0m"
__COLOR_RED="\033[0;31m"
__COLOR_YELLOW="\033[1;33m"

log_error() {
    local __BADGE_ERROR="${__COLOR_RED}[ERROR]${__COLOR_NONE}"
    echo -e "${__BADGE_ERROR} $1"
}

log_info() {
    local __BADGE_INFO="[INFO]"
    echo -e "${__BADGE_INFO} $1"
}

log_warning() {
    local __BADGE_WARN="${__COLOR_YELLOW}[WARN]${__COLOR_NONE}"
    echo -e "${__BADGE_WARN} $1"
}

# checking arguments

usage() {
    echo "Usage $0 -h API_HOST -k API_KEY -p PROJECT_ID -r REPO_PATH -t RELEASE_TAG -i RELEASE_INFO [ -j ASSET_JOB_ID -d ASSET_DESCRIPTION ]"
}

checkargs () {
    if [[ $OPTARG =~ ^-[h/k/p/r/t/i/j/d]$ ]]
    then
        log_error "Unknown argument \"$OPTARG\" for option \"-$OPT!\""
        exit 2
    fi
}

unknown_option() {
    log_error "Unknown option \"$1\""
    exit 3
}

# disable exit on error
set +e

# ensure we have some arguments
if [ $# -lt 1 ]
then
    usage
    exit 1
fi

# parse arguments
while getopts ":h:k:p:r:t:i:j:d:" OPT
do
    case $OPT in
        h)  checkargs
            __CI_API_HOST=$OPTARG
            ;;
        k)  checkargs
            __CI_API_KEY=$OPTARG
            ;;
        p)  checkargs
            __CI_PROJECT_ID=$OPTARG
            ;;
        r)  checkargs
            __CI_REPO_PATH=$OPTARG
            ;;
        t)  checkargs
            __CI_RELEASE_TAG=$OPTARG
            ;;
        i)  checkargs
            __CI_RELEASE_INFO=$OPTARG
            ;;
        j)  checkargs
            __CI_ASSET_JOB_ID=$OPTARG
            ;;
        d)  checkargs
            __CI_ASSET_DESCRIPTION=$OPTARG
            ;;
        *)  unknown_option "$OPT"
            ;;
    esac
done

# ensure we've CI variables specified
if [ -z "${__CI_API_HOST}" ]
then
    log_error "The __CI_API_HOST (-h) parameter wasn't specified or empty but it's required for the script."
    exit 4
fi
if [ -z "${__CI_API_KEY}" ]
then
    log_error "The __CI_API_KEY (-k) parameter wasn't specified or empty but it's required for the script."
    exit 4
fi
if [ -z "${__CI_PROJECT_ID}" ]
then
    log_error "The __CI_PROJECT_ID (-p) parameter wasn't specified or empty but it's required for the script."
    exit 4
fi
if [ -z "${__CI_REPO_PATH}" ]
then
    log_error "The __CI_REPO_PATH (-r) parameter wasn't specified or empty but it's required for the script."
    exit 4
fi
if [ -z "${__CI_RELEASE_TAG}" ]
then
    log_error "The __CI_RELEASE_TAG (-t) parameter wasn't specified or empty but it's required for the script."
    exit 4
fi
if [ -z "${__CI_RELEASE_INFO}" ]
then
    log_error "The __CI_RELEASE_INFO (-i) parameter wasn't specified or empty but it's required for the script."
    exit 4
fi

# ensure that asset description is specified when the asset job ID is specified
if [ -n "${__CI_ASSET_JOB_ID}" ] && [ -z "${__CI_ASSET_DESCRIPTION}" ]
then
    log_error "The __CI_ASSET_DESCRIPTION (-d) parameter wasn't specified or empty but it's required for the script when the __CI_ASSET_JOB_ID (-j) parameter is specified."
    exit 4
fi

__CI_API_PROJECT_URL="https://${__CI_API_HOST}/api/v4/projects/${__CI_PROJECT_ID}/"

# enable exit on error
set -e

# compose a create release body
__CI_API_RELEASE_CREATE_REQUEST_BODY="{"

# add a link to an asset if its data was specified
if [ -n "${__CI_ASSET_JOB_ID}" ]
then
    __CI_ASSET_JOB_URL="https://${__CI_API_HOST}/${__CI_REPO_PATH}/-/jobs/${__CI_ASSET_JOB_ID}/artifacts/download"
    __CI_API_RELEASE_CREATE_REQUEST_BODY="${__CI_API_RELEASE_CREATE_REQUEST_BODY}
  \"assets\": {
    \"links\": [
      {
        \"name\": \"${__CI_ASSET_DESCRIPTION}\",
        \"url\": \"${__CI_ASSET_JOB_URL}\"
      }
    ]
  },"
fi

__CI_API_RELEASE_CREATE_REQUEST_BODY="${__CI_API_RELEASE_CREATE_REQUEST_BODY}
  \"description\": \"${__CI_RELEASE_INFO}\",
  \"name\": \"${__CI_RELEASE_TAG}\",
  \"tag_name\": \"${__CI_RELEASE_TAG}\"
}"

# create a realease
__CI_API_RELEASE_CREATE_RESPONSE_BODY=`curl -f -sS \
    --header 'Content-Type: application/json' \
    --header "PRIVATE-TOKEN: ${__CI_API_KEY}" \
    --data "${__CI_API_RELEASE_CREATE_REQUEST_BODY}" \
    --request POST "${__CI_API_PROJECT_URL}releases"`

log_info "Successfully created a release for tag \"${__CI_RELEASE_TAG}\""
