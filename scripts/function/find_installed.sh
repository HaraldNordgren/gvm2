# find_installed
#

# source once and only once!
[[ ${GVM_FIND_INSTALLED:-} -eq 1 ]] && return || readonly GVM_FIND_INSTALLED=1

# load dependencies
g_path_script="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && /bin/pwd)"
. "${g_path_script}/_bash_pseudo_hash" || return 1
. "${g_path_script}/tools" || return 1

# __gvm_find_installed()
# /*!
# @abstract Find all installed versions of go.
# @discussion
# Searches the installed_path specified or $GVM_ROOT/gos directory; resolves
#   the system installed go if it exists.
# @param target [optional] Go version to find
# @param installed_path [optional] Go install path (directory to installed gos)
# @return Returns an pseudo hash (status 0) where keys are Go versions and
#   values are paths to Go version installations or an empty string (status 1)
#   on failure.
# */
__gvm_find_installed()
{
    local target="${1}"; shift
    local installed_path="${1:-$GVM_ROOT/gos}"
    local installed_hash; installed_hash=()
    local versions_hash; versions_hash=()

    [[ -d "${installed_path}" ]] || (echo "" && return 1)

    if [[ -z "${target}" ]]
    then
        installed_hash=( $("${LS_PATH}" -1 "${installed_path}") )
        for (( i=0; i<${#installed_hash[@]}; i++ ))
        do
            local __key __val
            __key="${installed_hash[i]}"
            __val="${installed_path}/${__key}"

            # system is a special case
            if [[ "${__key}" == "system" ]]
            then
                # resolve path from environment!
                __val="$(sed -n -e 's/^\(.*GOROOT=.*\)$/\1/g' \
                    -e 's/\"//g' \
                    -e 's/^.*GOROOT=//gp' "${GVM_ROOT}/environments/system")"
            fi

            versions_hash=( $(setValueForKeyFakeAssocArray "${__key}" "${__val}" "${versions_hash[*]}") )
            unset __key __val
        done
    else
        if [[ -d "${installed_path}/${target}" ]]
        then
            local __key __val
            __key="${target}"
            __val="${installed_path}/${__key}"
            versions_hash=( $(setValueForKeyFakeAssocArray "${__key}" "${__val}" "${versions_hash[*]}") )
            unset __key __val
        fi
    fi

    unset installed_hash
    unset installed_path
    unset target

    if [[ ${#versions_hash[@]} -eq 0 ]]
    then
        unset versions_hash
        echo "" && return 1
    fi

    printf "%s" "${versions_hash[*]}"

    unset versions_hash
    return 0
}
