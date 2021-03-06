#!/usr/bin/env bash
#
# shellcheck shell=bash
# vi: set ft=bash
#

# source once and only once!
[[ ${GVM_ENV:-} -eq 1 ]] && return || readonly GVM_ENV=1

# load dependencies
dep_load()
{
    local srcd="${BASH_SOURCE[0]}"; srcd="${srcd:-${(%):-%x}}"
    local base="$(builtin cd "$(dirname "${srcd}")" && builtin pwd)"
    local deps; deps=(
        "../function/_shell_compat.sh"
        "../function/display_notices.sh"
        "../function/locale_text.sh"
        "pkgset_use.sh"
        "use.sh"
    )
    for file in "${deps[@]}"
    do
        source "${base}/${file}"
    done
}; dep_load; unset -f dep_load &> /dev/null || unset dep_load

__gvmp_sanity_check() {
    if [ -z "${GVM_ROOT// /}" ]
    then
        if [ -n "${ZSH_NAME// /}" ]; then
            __gvm_locale_text_for_key "gvmroot_not_set_long_zsh" > /dev/null
        else
            __gvm_locale_text_for_key "gvmroot_not_set_long_bash" > /dev/null
        fi
        __gvm_display_error "${RETVAL}"
    fi

    # check for all required utility dependencies
    "${GVM_ROOT}/scripts/check" "--skip" "hg" &> /dev/null
    if [[ "$?" != "0" ]]
    then
        __gvm_locale_text_for_key "missing_requirements_long" > /dev/null
        __gvm_display_error "${RETVAL}"
    fi

    return $?
}

# gvm2()
# /*!
# @abstract Alias of the gvm() function.
# */
gvm2() {
    gvm "$@"; return $?
}

# gvm()
# /*!
# @abstract Main gvm entry point.
# @discussion
# This function will end up calling one of the following scripts:
#   + scripts/env/use
#   + scripts/env/pkgset_use
#   + bin/gvm
# @param command [optional] The GVM command to execute
# @param sub_command [optional] The GVM sub_command to execute (only works with
#   pkgset command)
# @return Returns success (status 0) or failure (status 1).
# */
gvm() {
    local command="${1}"
    local sub_command=""

    # shift commands off of the arg list, pkgset requires a sub_command
    case "${command}" in
        pkgset)
            sub_command="${2}"
            # all pkgset commands are passed on with args except for "use"
            if [[ "${sub_command}" == "use" ]]
            then
                shift; shift
            fi
            ;;
        use)
            shift
            ;;
        *)
            ;;
    esac

    if [[ -z "${GVM_ROOT// /}" ]]; then
        __gvm_locale_text_for_key "gvmroot_not_set" > /dev/null
        __gvm_display_error "${RETVAL} \'source \${GVM_ROOT}/scripts/gvm\'."
        return 1
    fi
    if [[ -z "${GVM_NO_GIT_BAK// /}" && -d "${GVM_ROOT}/.git" ]]; then
        __gvm_locale_text_for_key "gvmgit_directory_present" > /dev/null
        __gvm_display_error "${RETVAL}"
        return 1
    fi
    if [[ ! -d "${GVM_ROOT}" ]]; then
        __gvm_locale_text_for_key "gvmroot_not_exist" > /dev/null
        __gvm_display_error "${RETVAL}"
        return 1
    fi

    mkdir -p "${GVM_ROOT}/logs" > /dev/null 2>&1
    mkdir -p "${GVM_ROOT}/gos" > /dev/null 2>&1
    mkdir -p "${GVM_ROOT}/archive" > /dev/null 2>&1
    mkdir -p "${GVM_ROOT}/archive/package" > /dev/null 2>&1
    mkdir -p "${GVM_ROOT}/environments" > /dev/null 2>&1

    if [[ "${command}" == "use" ]]; then
        __gvmp_sanity_check || return 1
        __gvm_use "$@"
    elif [[ "${command}" == "pkgset" ]] && [[ "${sub_command}" == "use" ]]; then
        __gvmp_sanity_check || return 1
        __gvm_pkgset_use "$@"
    else
        "${GVM_ROOT}/bin/gvm" "$@"
    fi

    return $?
}
