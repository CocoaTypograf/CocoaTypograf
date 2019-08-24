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
    echo "Usage $0 -l LOGIN -k AUTH_KEY -h HOST -p PROJECT_PATH -a COMMIT_AUTHOR_NAME -e COMMIT_AUTHOR_EMAL"
}

checkargs () {
    if [[ $OPTARG =~ ^-[l/k/h/p/a/e]$ ]]
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
while getopts ":l:k:h:p:a:e:" OPT
do
    case $OPT in
        l)  checkargs
            __CI_LOGIN=$OPTARG
            ;;
        k)  checkargs
            __CI_AUTH_KEY=$OPTARG
            ;;
        h)  checkargs
            __CI_GIT_HOST=$OPTARG
            ;;
        p)  checkargs
            __CI_GIT_PROJECT_PATH=$OPTARG
            ;;
        a)  checkargs
            __CI_COMMIT_AUTHOR_NAME=$OPTARG
            ;;
        e)  checkargs
            __CI_COMMIT_AUTHOR_EMAIL=$OPTARG
            ;;
        *)  unknown_option "$OPT"
            ;;
    esac
done

# ensure we've CI variables specified
if [ -z "${__CI_LOGIN}" ]
then
    log_error "The __CI_LOGIN (-l) parameter wasn't specified or empty but it's required for the script."
    exit 4
fi
if [ -z "${__CI_AUTH_KEY}" ]
then
    log_error "The __CI_AUTH_KEY (-k) parameter wasn't specified or empty but it's required for the script."
    exit 4
fi
if [ -z "${__CI_GIT_HOST}" ]
then
    log_error "The __CI_GIT_HOST (-h) parameter wasn't specified or empty but it's required for the script."
    exit 4
fi
if [ -z "${__CI_GIT_PROJECT_PATH}" ]
then
    log_error "The __CI_GIT_PROJECT_PATH (-p) parameter wasn't specified or empty but it's required for the script."
    exit 4
fi
if [ -z "${__CI_COMMIT_AUTHOR_NAME}" ]
then
    log_error "The __CI_COMMIT_AUTHOR_NAME (-a) parameter wasn't specified or empty but it's required for the script."
    exit 4
fi
if [ -z "${__CI_COMMIT_AUTHOR_EMAIL}" ]
then
    log_error "The __CI_COMMIT_AUTHOR_EMAIL (-e) parameter wasn't specified or empty but it's required for the script."
    exit 4
fi

# ensure we've git-flow installed
__GIT_FLOW_CHECK=`command -v git-flow`
__GIT_FLOW_CHECK_CODE=$?
if [ ${__GIT_FLOW_CHECK_CODE} -ne 0 ] || [ ! -x ${__GIT_FLOW_CHECK} ]
then
    log_error "Git-flow is not installed on current Gitlab runner machine. Please install git-flow first via \"brew install git-flow-avh\"."
    exit 5
fi

__CI_URL="https://${__CI_LOGIN}:${__CI_AUTH_KEY}@${__CI_GIT_HOST}/${__CI_GIT_PROJECT_PATH}.git"

# update the git config to use CI Bot as an author
git config user.name "${__CI_COMMIT_AUTHOR_NAME}"
git config user.email "${__CI_COMMIT_AUTHOR_EMAIL}"

# enable exit on error
set -e

# 0. fetch all remotes 
git fetch --all --prune

# 1. checkout and pull master branch
git checkout master
git reset --hard
git pull

# 2. checkout and pull develop branch
git checkout develop
git reset --hard
git pull

# 3. ensure git flow is enabled
git flow config | git flow init -d

# 4. get current version
__CURRENT_VERSION=`agvtool what-version -terse | perl -pe 'chomp'`
log_info "Current version number is ${__CURRENT_VERSION}"

# 5. increment version number
# TODO: Add conditional increment of components of a version number
__CURRENT_VERSION=`echo "${__CURRENT_VERSION}" | perl -pe 's/^((\d+\.)*)(\d+)(.*)$/$1.($3+1).$4/e'`
log_info "Incrementing the last version number to ${__CURRENT_VERSION}"

# 6. make a new release branch
git flow release start "${__CURRENT_VERSION}"

# 7. assign version number to the CFBundleShortVersionString
agvtool -noscm new-version "${__CURRENT_VERSION}"

# 8. make a new commit with the new version
git add **/*.pbxproj
git commit --author="${__CI_COMMIT_AUTHOR_NAME} <${__CI_COMMIT_AUTHOR_EMAIL}>" -m "Update the app version to v${__CURRENT_VERSION}"

# 9. finish the release branch
export GIT_MERGE_AUTOEDIT=no
git flow release finish -m "${__CURRENT_VERSION}" "${__CURRENT_VERSION}"
unset GIT_MERGE_AUTOEDIT

# 10. push the changes to the origin
git push --tags "${__CI_URL}"
git push "${__CI_URL}" develop
git push "${__CI_URL}" master

# 11. checkout back to develop
git checkout develop
