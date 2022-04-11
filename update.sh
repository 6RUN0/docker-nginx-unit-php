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
		cp *.sh  "$distr/$suite/"
		rm -f "$distr/$suite/update.sh" 
		sed -r \
			-e 's/%%DISTR%%/'"$distr"'/' \
			-e 's/%%SUITE%%/'"$suite"'/' \
			"Dockerfile.template" > "$distr/$suite/Dockerfile"
	done
done
