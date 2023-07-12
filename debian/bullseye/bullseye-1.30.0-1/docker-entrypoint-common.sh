#!/bin/sh -

if [ -z "${UNIT_ENTRYPOINT_QUIET_LOGS:-}" ]; then
    exec 3>&2
else
    exec 3>/dev/null
fi

ngx_log() {
	local type="$1"; shift
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
