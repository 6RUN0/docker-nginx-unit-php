#!/usr/bin/env bash

set -Eeuox pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

distrs=("$@")

if [ ${#distrs[@]} -eq 0 ]; then
    GLOBIGNORE=".*:latest/"
    distrs=(*/)
fi

distrs=("${distrs[@]%/}")
php_versions="7.4 8.1 8.2 8.3"

for distr in "${distrs[@]}"; do
    for suite in "$distr"/*; do
        suite=${suite##*/}
        versions=$(wget -O - "https://packages.nginx.org/unit/$distr/pool/unit/u/unit/" | sed -n -E -e "s/<a.+?>unit_(.+?)~${suite}_amd64.deb<\/a>.*/\1/p" | sort -u | grep -v "1\.2[2-8]")
        if [ "$distr" = "debian" ]; then
            image_suffix="-slim"
        else
            image_suffix=""
        fi
        for ver in $versions; do
            for php_ver in $php_versions; do
                dst_dir="${distr}/${suite}/${suite}-${ver}-php${php_ver}/"
                mkdir -p "$dst_dir"
                cp *.sh "$dst_dir"
                rm -f "${dst_dir}update.sh"
                dockerfile="${dst_dir}Dockerfile"
                template="Dockerfile.$distr.$suite.$php_ver.template"
                if [ ! -r "$template" ]; then
                    template="Dockerfile.$distr.$suite.template"
                fi
                if [ ! -r "$template" ]; then
                    template="Dockerfile.$distr.template"
                fi
                if [ ! -r "$template" ]; then
                    template="Dockerfile.template"
                fi
                sed -r \
                    -e 's/%%DISTR%%/'"$distr"'/' \
                    -e 's/%%SUITE%%/'"$suite"'/' \
                    -e 's/%%VERSION%%/'"$ver"'/' \
                    -e 's/%%IMAGE_SUFFIX%%/'"$image_suffix"'/' \
                    -e 's/%%PHP_VER%%/'"$php_ver"'/' \
                    "$template" >"$dockerfile"
            done
        done
    done
done
