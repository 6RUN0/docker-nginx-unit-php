#!/usr/bin/env bash

set -Eeuox pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

distrs=( "$@" )

if [ ${#distrs[@]} -eq 0 ]; then
	GLOBIGNORE=".*:tests"
	distrs=( */ )
fi

distrs=( "${distrs[@]%/}" )

for distr in "${distrs[@]}"; do
	suites=( $distr/* )
	suites=( "${suites##*/}" )
	for suite in "$suites"; do
		versions=$(wget -O - https://packages.nginx.org/unit/$distr/pool/unit/u/unit/ | sed -n -E -e "s/<a.+?>unit_(.+?)~${suite}_amd64.deb<\/a>.*/\1/p" | sort -u)
		if [ "$distr" = "debian" ]; then
			image_suffix="-slim"
		else
			image_suffix=""
		fi
		for ver in $versions; do
			mkdir -p "$distr/$suite/$ver/"
			cp *.sh  "$distr/$suite/$ver/"
			rm -f "$distr/$suite/$ver/update.sh" 
			dockerfile="$distr/$suite/$ver/Dockerfile"
			sed -r \
				-e 's/%%DISTR%%/'"$distr"'/' \
				-e 's/%%SUITE%%/'"$suite"'/' \
				-e 's/%%VERSION%%/'"$ver"'/' \
				-e 's/%%IMAGE_SUFFIX%%/'"$image_suffix"'/' \
				"Dockerfile.template" > "$dockerfile"
			if [ "$suites" = "jammy" ]; then
				sed -i -e '/php-apcu-bc/d' "$dockerfile"
			fi
		done
	done
done
