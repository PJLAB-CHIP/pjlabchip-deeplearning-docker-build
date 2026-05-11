#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION_FILE="${REPO_ROOT}/scripts/image-configs.sh"

BUMP_TYPE=""
DO_PUSH="false"

print_help() {
    cat <<'EOF'
Usage: ./scripts/next-version.sh [--patch|--minor|--major] [--push]

Bump the release version, commit current changes, tag the commit, and optionally push
the branch plus tag to origin to trigger the GitHub workflow.

Options:
  --patch                    Bump the patch version. Default when no bump flag is set.
  --minor                    Bump the minor version and reset patch to 0.
  --major                    Bump the major version and reset minor and patch to 0.
  --push                     Push the current branch and new tag to origin.
  -h, --help                 Show this help message and exit.

Examples:
  ./scripts/next-version.sh --patch
  ./scripts/next-version.sh --minor --push
  ./scripts/next-version.sh --major --push
EOF
}

error() {
    printf '[next-version.sh] ERROR: %s\n' "$1" >&2
    exit 1
}

bump_version() {
    local version="$1"
    local bump="$2"
    local major minor patch

    if [[ ! "${version}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        error "Unsupported version format: ${version}"
    fi

    major="${BASH_REMATCH[1]}"
    minor="${BASH_REMATCH[2]}"
    patch="${BASH_REMATCH[3]}"

    case "${bump}" in
        patch)
            patch="$((patch + 1))"
            ;;
        minor)
            minor="$((minor + 1))"
            patch=0
            ;;
        major)
            major="$((major + 1))"
            minor=0
            patch=0
            ;;
        *)
            error "Unsupported bump type: ${bump}"
            ;;
    esac

    printf '%s.%s.%s\n' "${major}" "${minor}" "${patch}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --patch|--minor|--major)
            if [[ -n "${BUMP_TYPE}" ]]; then
                error "Only one bump flag can be provided."
            fi
            BUMP_TYPE="${1#--}"
            shift
            ;;
        --push)
            DO_PUSH="true"
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            error "Unknown argument: $1"
            ;;
    esac
done

if [[ -z "${BUMP_TYPE}" ]]; then
    BUMP_TYPE="patch"
fi

if [[ ! -f "${VERSION_FILE}" ]]; then
    error "Version file not found: ${VERSION_FILE}"
fi

source "${VERSION_FILE}"

if [[ -z "${IMAGE_VERSION:-}" ]]; then
    error "IMAGE_VERSION is not set in ${VERSION_FILE}"
fi

CURRENT_VERSION="${IMAGE_VERSION}"
NEW_VERSION="$(bump_version "${CURRENT_VERSION}" "${BUMP_TYPE}")"
NEW_TAG="v${NEW_VERSION}"

if git -C "${REPO_ROOT}" rev-parse -q --verify "refs/tags/${NEW_TAG}" >/dev/null; then
    error "Tag already exists: ${NEW_TAG}"
fi

sed -i "s/^IMAGE_VERSION=.*/IMAGE_VERSION=${NEW_VERSION}/" "${VERSION_FILE}"

git -C "${REPO_ROOT}" add -A
git -C "${REPO_ROOT}" commit --allow-empty -m "[UPDATE][${NEW_TAG}] Bump image version"
git -C "${REPO_ROOT}" tag "${NEW_TAG}"

printf '[next-version.sh] Created commit and tag %s from %s\n' "${NEW_TAG}" "${CURRENT_VERSION}"

if [[ "${DO_PUSH}" == "true" ]]; then
    CURRENT_BRANCH="$(git -C "${REPO_ROOT}" branch --show-current)"

    if [[ -z "${CURRENT_BRANCH}" ]]; then
        error "Cannot push from a detached HEAD."
    fi

    git -C "${REPO_ROOT}" push origin "${CURRENT_BRANCH}"
    git -C "${REPO_ROOT}" push origin "${NEW_TAG}"
    printf '[next-version.sh] Pushed %s and %s to origin\n' "${CURRENT_BRANCH}" "${NEW_TAG}"
else
    printf '[next-version.sh] Run with --push to publish the branch and tag to origin.\n'
fi
