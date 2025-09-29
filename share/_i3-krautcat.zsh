#compdef i3-krautcat
compdef _i3-krautcat i3-krautcat

function _i3-krautcat() {
    local curcontext="$curcontext" state state_descr line context
    typeset -A opt_args

    local ret
    ret=0

    _arguments -C \
        '(- : *)'{-h,--help}'[display help information]' \
        '1:subcommands:_i3-krautcat_subcommands' \
        '*::subcommands:->command' \
        && ret=0

    case $state in
        (command)
            echo "${words[CURRENT]} ${words[2]}" >> /tmp/i3-krautcat_completion.log   
            local _command
            _command="${words[1]}"
            echo "_i3-krautcat_$_command" >> /tmp/i3-krautcat_completion.log
            (( $+functions[_i3-krautcat_$_command] )) && _i3-krautcat_$_command
            ;;
    esac

    return $ret
}

_i3-krautcat_rename() {
    local -a opts

    opts+=(
        '(-s --source)'{-s,--source}'[source workspace name]:workspace:_i3-krautcat_list'
        '(-d --dest)'{-d,--dest}'[target workspace name]:workspace: '
    )

    _arguments "${opts[@]}"
}

_i3-krautcat_subcommands() {
    local -a subcommands
    subcommands=(
        "automove:Automatically move workspaces to screens"
        "list:List all workspaces"
        "rename:Rename workspace"
    )

    _describe -t subcommands 'subcommands' subcommands
}

_i3-krautcat_automove() {
    return
}

_i3-krautcat_list() {
    local -a workspaces
   
    local IFS
    IFS=$'\n' 
    workspaces=($(i3-krautcat list))

    _alternative "workspace:workspace name:('${workspaces[@]}')"
}

[ "$funcstack[1]" = "_i3-krautcat" ] && _i3-krautcat "$@"
