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
    echo "Usage $0 -k API_KEY -r REPO_PATH -t RELEASE_TAG -i RELEASE_INFO [ -a ASSET_FILE_PATH [-n CUSTOM_ASSET_FILE_NAME] [-d CUSTOM_ASSET_FILE_DESCRIPTION] ]"
}

checkargs () {
    if [[ $OPTARG =~ ^-[k/r/t/i/a/n/d]$ ]]
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
while getopts ":k:r:t:i:a:n:d:" OPT
do
    case $OPT in
        k)  checkargs
            __CI_API_KEY=$OPTARG
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
        a)  checkargs
            __CI_ASSET_FILE_PATH=$OPTARG
            ;;
        n)  checkargs
            __CI_ASSET_FILE_NAME=$OPTARG
            ;;
        d)  checkargs
            __CI_ASSET_DESCRIPTION=$OPTARG
            ;;
        *)  unknown_option "$OPT"
            ;;
    esac
done

# ensure we've CI variables specified
if [ -z "${__CI_API_KEY}" ]
then
    log_error "The __CI_API_KEY (-k) parameter wasn't specified or empty but it's required for the script."
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

# check if an asset file path is specified
if [ -n "${__CI_ASSET_FILE_PATH}" ]
then
    # ensure the asset file exist when the file path is specified
    if [ ! -s "${__CI_ASSET_FILE_PATH}" ]
    then
        log_error "The specified __CI_ASSET_FILE_PATH (-a) parameter (\"${__CI_ASSET_FILE_PATH}\") is pointing to an empty or non-existent file when the parameter is specified an existing file is required at the path for the script."
        exit 4
    fi

    # assign a basename based asset file name if it is not specified
    if [ -z "${__CI_ASSET_FILE_NAME}" ]
    then
        __CI_ASSET_FILE_NAME=`basename "${__CI_ASSET_FILE_PATH}"`
        log_warning "The __CI_ASSET_FILE_NAME (-n) parameter wasn't specified. Using filename from the specified asset file path (${__CI_ASSET_FILE_PATH}): \"${__CI_ASSET_FILE_NAME}\""
    fi
fi


__CI_API_PROJECT_URL="https://api.github.com/repos/${__CI_REPO_PATH}/"

# enable exit on error
set -e

# create a release
__CI_API_RELEASE_CREATE_REQUEST_BODY="{
  \"tag_name\": \"${__CI_RELEASE_TAG}\",
  \"target_commitish\": \"master\",
  \"name\": \"${__CI_RELEASE_TAG}\",
  \"body\": \"${__CI_RELEASE_INFO}\",
  \"draft\": false,
  \"prerelease\": false
}"
__CI_API_RELEASE_CREATE_RESPONSE_BODY=`curl -f -sS \
    --header "Accept: application/json" \
    --header "Authorization: token ${__CI_API_KEY}" \
    --header 'Content-Type: application/json' \
    --data "${__CI_API_RELEASE_CREATE_REQUEST_BODY}" \
    --request POST "${__CI_API_PROJECT_URL}releases"`

# parse ID from create release response
__CI_API_RELEASE_ID=`echo "${__CI_API_RELEASE_CREATE_RESPONSE_BODY}" | perl -MData::Dumper -MJSON::PP=decode_json -e '\
    $/=undef; \
    my $data=<>; \
    my $response=decode_json($data); \
    print $id=$response->{"id"}'`
log_info "Successfully created a release for tag \"${__CI_RELEASE_TAG}\" with ID ${__CI_API_RELEASE_ID}"

# if an asset file path is specified, perform asset upload operations
if [ -n "${__CI_ASSET_FILE_PATH}" ]
then
    # parse upload URL from create release response
    __CI_API_RESPONSE_RELEASE_UPLOAD_URL=`echo "${__CI_API_RELEASE_CREATE_RESPONSE_BODY}" | perl -MData::Dumper -MJSON::PP=decode_json -e '\
        $/=undef; \
        my $data=<>; \
        my $response=decode_json($data); \
        print $response->{"upload_url"} =~ s/\{\?name,label\}//r'`

    # ensure we got assets upload URL
    if [ -z "${__CI_API_RESPONSE_RELEASE_UPLOAD_URL}" ]
    then
        log_error "Failed to obtain an assets upload URL after creating a release #${__CI_API_RELEASE_ID}."
        exit 5
    fi

    # get the asset MIME type
    __CI_ASSET_FILE_MIME_TYPE=`file --mime-type -b "${__CI_ASSET_FILE_PATH}"`

    # compose the upload URL
    __CI_ASSET_FILE_NAME_ENCODED=`echo "${__CI_ASSET_FILE_NAME}" | perl -MURI::Escape -ne 'chomp;print uri_escape($_),"\n"'`
    __CI_API_RELEASE_ASSET_UPLOAD_REQUEST_URL="${__CI_API_RESPONSE_RELEASE_UPLOAD_URL}?name=${__CI_ASSET_FILE_NAME_ENCODED}"
    if [ -n "${__CI_ASSET_DESCRIPTION}" ]
    then
        __CI_ASSET_DESCRIPTION_ENCODED=`echo "${__CI_ASSET_DESCRIPTION}" | perl -MURI::Escape -ne 'chomp;print uri_escape($_),"\n"'`
        __CI_API_RELEASE_ASSET_UPLOAD_REQUEST_URL="${__CI_API_RELEASE_ASSET_UPLOAD_REQUEST_URL}&label=${__CI_ASSET_DESCRIPTION_ENCODED}"
    fi

    # upload a release asset
    __CI_API_RELEASE_ASSET_UPLOAD_RESPONSE_BODY=`curl -f -sS \
        --header "Accept: application/json" \
        --header "Authorization: token ${__CI_API_KEY}" \
        --header 'Content-Type: ${__CI_ASSET_FILE_MIME_TYPE}' \
        --data-binary "@${__CI_ASSET_FILE_PATH}" \
        --request POST "${__CI_API_RELEASE_ASSET_UPLOAD_REQUEST_URL}"`

    # parse asset ID from upload asset response
    __CI_API_RELEASE_ASSET_ID=`echo "${__CI_API_RELEASE_ASSET_UPLOAD_RESPONSE_BODY}" | perl -MData::Dumper -MJSON::PP=decode_json -e '\
        $/=undef; \
        my $data=<>; \
        my $response=decode_json($data); \
        print $id=$response->{"id"}'`
    if [ -n "${__CI_ASSET_DESCRIPTION}" ]
    then
        log_info "Successfully uploaded an asset named \"${__CI_ASSET_FILE_NAME}\" (\"${__CI_ASSET_DESCRIPTION}\") with ID ${__CI_API_RELEASE_ASSET_ID}"
    else
        log_info "Successfully uploaded an asset named \"${__CI_ASSET_FILE_NAME}\" with ID ${__CI_API_RELEASE_ASSET_ID}"
    fi
fi
