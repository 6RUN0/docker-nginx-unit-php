#!/usr/bin/env bash

if [ -z "${UNIT_ENTRYPOINT_QUIET_LOGS:-}" ]; then
    exec 3>&2
else
    exec 3>/dev/null
fi

ngx_log() {
    local type="$1"
    shift
    printf '%s [%s] %s#%s [entrypoint] #0: %s\n' "$(date +'%Y/%m/%d %H:%M:%S')" "$type" "$$" "$$" "$*" >&3
}

ngx_err() {
    ngx_log err "$@"
    exit 1
}

ngx_warning() {
    ngx_log warning "$@"
}

ngx_notice() {
    ngx_log notice "$@"
}

ngx_info() {
    ngx_log info "$@"
}

curl_put() {
    RET=$(curl -s -w '%{http_code}' -X PUT --data-binary "@$1" --unix-socket "/var/run/control.unit.sock http://localhost/$2")
    RET_BODY=${RET::-3}
    RET_STATUS=$(echo "$RET" | tail -c 4)
    if [ "$RET_STATUS" -ne "200" ]; then
        ngx_error "HTTP response status code is '$RET_STATUS'. Body: $RET_BODY"
    else
        ngx_info "HTTP response status code is '$RET_STATUS'. Body: $RET_BODY"
    fi
    return 0
}

APPLICATION_USER=${APPLICATION_USER:="unit"}
APPLICATION_UID=${APPLICATION_UID:="1000"}
APPLICATION_GROUP=${APPLICATION_GROUP:="unit"}
APPLICATION_GID=${APPLICATION_GID:="1000"}
APPLICATION_CHOWN=${APPLICATION_CHOWN:="yes"}

if [ -z $(getent group "$APPLICATION_GROUP") ]; then
    ngx_info "create app group: '$APPLICATION_GROUP'"
    groupadd "$APPLICATION_GROUP" -g "$APPLICATION_GID"
fi

if [ -z $(getent passwd "$APPLICATION_USER") ]; then
    ngx_info "create app user: '$APPLICATION_USER'"
    useradd -M -s /bin/bash -g "$APPLICATION_GROUP" -u "$APPLICATION_UID" "$APPLICATION_USER"
fi

if [ -n "$APPLICATION_DIR" ]; then
    if [ ! -d "$APPLICATION_DIR" ]; then
        ngx_info "create app dir: '$APPLICATION_DIR'"
        mkdir -p "$APPLICATION_DIR"
    fi
    usermod --home "$APPLICATION_DIR" "$APPLICATION_USER" &>/dev/null
    if [ "x$APPLICATION_CHOWN" = "xyes" ]; then
        find "$APPLICATION_DIR" \! -user "$APPLICATION_USER" -exec chown "$APPLICATION_USER":"$APPLICATION_GROUP" '{}' +
    fi
fi
