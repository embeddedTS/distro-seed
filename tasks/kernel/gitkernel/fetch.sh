#!/bin/bash -e

SOURCE="$DS_STAGING/source"

install -d "$DS_STAGING"

# If the url is a locally cloned git, we use the local head hash as the cache key
if [[ -d "$CONFIG_DS_KERNEL_PROVIDER_GIT_URL" ]]; then
    pushd "$CONFIG_DS_KERNEL_PROVIDER_GIT_URL" > /dev/null

    if [[ -n $(git status --porcelain --untracked-files=no) ]]; then
        echo "Error: Local Git repository is dirty. Please commit or stash your changes."
        exit 1
    fi

    if [[ -n "$CONFIG_DS_KERNEL_PROVIDER_GIT_VERSION" ]]; then
        git checkout "$CONFIG_DS_KERNEL_PROVIDER_GIT_VERSION"
    fi

    popd > /dev/null
    common/host/fetch_dir.sh "$CONFIG_DS_KERNEL_PROVIDER_GIT_URL" "$SOURCE"
else
        # Remote git
        install -d "$SOURCE"
        common/host/fetch_git.sh "$CONFIG_DS_KERNEL_PROVIDER_GIT_URL" "$CONFIG_DS_KERNEL_PROVIDER_GIT_VERSION" "$SOURCE"
fi
