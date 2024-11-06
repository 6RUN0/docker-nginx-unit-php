#!/usr/bin/env bash

set -e

. /docker-entrypoint-common.sh

if [ "$1" = "unitd" -o "$1" = "unitd-debug" ]; then
    if find "/var/lib/unit/" -type f -print -quit 2>/dev/null | grep -q .; then
        ngx_notice "/var/lib/unit/ is not empty, skipping initial configuration..."
    else
        if find "/docker-entrypoint.d/" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
            ngx_info "/docker-entrypoint.d/ is not empty, launching Unit daemon to perform initial configuration..."
            /usr/sbin/$1 --control unix:/var/run/control.unit.sock

            while [ ! -S /var/run/control.unit.sock ]; do
                ngx_info "waiting for control socket to be created..."
                sleep 0.1
            done
            # even when the control socket exists, it does not mean unit has finished initialisation
            # this curl call will get a reply once unit is fully launched
            curl -s -X GET --unix-socket /var/run/control.unit.sock http://localhost/

            ngx_info "looking for shell scripts in /docker-entrypoint.d/..."
            for f in $(find /docker-entrypoint.d/ -type f -name "*.sh"); do
                ngx_info "launching $f"
                "$f"
            done

            ngx_info "looking for certificate bundles in /docker-entrypoint.d/..."
            for f in $(find /docker-entrypoint.d/ -type f -name "*.pem"); do
                ngx_info "uploading certificates bundle: $f"
                curl_put $f "certificates/$(basename $f .pem)"
            done

            ngx_info "looking for configuration snippets in /docker-entrypoint.d/..."
            for f in $(find /docker-entrypoint.d/ -type f -name "*.json"); do
                ngx_info "applying configuration $f"
                curl_put $f "config"
            done

            # warn on filetypes we don't know what to do with
            for f in $(find /docker-entrypoint.d/ -type f -not -name "*.sh" -not -name "*.json" -not -name "*.pem"); do
                ngx_notice "ignoring $f"
            done

            ngx_info "stopping Unit daemon after initial configuration..."
            kill -TERM $(cat /var/run/unit.pid)

            while [ -S /var/run/control.unit.sock ]; do
                ngx_info "waiting for control socket to be removed..."
                sleep 0.1
            done

            ngx_notice "unit initial configuration complete; ready for start up..."
        else
            ngx_notice "/docker-entrypoint.d/ is empty, skipping initial configuration..."
        fi
    fi
fi

exec "$@"
