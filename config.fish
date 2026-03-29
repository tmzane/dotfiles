# Setup environment.
set --export EDITOR                  'nvim'
set --export MANPAGER                'nvim +Man!'
set --export BAT_THEME               'base16'
set --export CONTAINER_RUNNER        'podman'
set --export HOMEBREW_NO_ANALYTICS   '1'
set --export HOMEBREW_NO_AUTO_UPDATE '1'
set --export FZF_DEFAULT_OPTS        '--border=none --inline-info'
set --export XDG_CONFIG_HOME         "$HOME/.config"

# Setup $PATH.
fish_add_path --global --path --move /opt/homebrew/bin
fish_add_path --global --path --move ~/go/bin

# Setup prompt.
set fish_greeting ''
starship init fish | source

# Setup VI mode.
fish_vi_key_bindings
set fish_cursor_default  block blink
set fish_cursor_insert   line  blink
set fish_cursor_external line  blink # For REPLs.

# Setup keymaps.
# https://fishshell.com/docs/current/interactive.html#shared-bindings
# https://fishshell.com/docs/current/interactive.html#vi-mode-commands
bind --mode default ctrl-z _fuzzy_jobs repaint
bind --mode insert  ctrl-z _fuzzy_jobs repaint
bind --mode insert  ctrl-f _fuzzy_find
bind --mode insert  ctrl-r _fuzzy_history

# Setup aliases.
alias cat 'bat'
alias top 'htop'
alias vim 'nvim'
alias fd  'LS_COLORS="" command fd' # https://github.com/sharkdp/fd/issues/1031

# Setup abbreviations.
abbr --add ga  'git add'
abbr --add gap 'git add --patch'
abbr --add gc  'git commit'
abbr --add gcm 'git commit --message'
abbr --add gd  'git diff'
abbr --add gdh 'git diff HEAD'
abbr --add gds 'git diff --staged'
abbr --add gf  'git fetch'
abbr --add gl  'git log -10 --oneline'
abbr --add gp  'git push'
abbr --add gpf 'git push --force-with-lease'
abbr --add gpl 'git pull'
abbr --add gr  'git rebase'
abbr --add gri 'git rebase --interactive'
abbr --add gs  'git status --short'
abbr --add gst 'git stash'
abbr --add gsw 'git switch'
abbr --add gwt 'git worktree'
abbr --add py  'python3'

function vimgrep
    rg --vimgrep $argv | nvim -q - +copen
end

function vimfind
    nvim $(fd --type=file --full-path --hidden --no-require-git $argv)
end

function _fuzzy_jobs
    if not builtin jobs --query
        return
    end

    set --local fzf_opts \
        --select-1 \
        --nth=4 \
        --accept-nth=2 \
        --prompt='Jobs: '

    jobs | fzf $fzf_opts | read --local pid; and builtin fg $pid 2>/dev/null
end

function _fuzzy_find
    set --local fd_opts \
        --hidden \
        --color=always \
        --no-require-git

    set --local fzf_opts \
        --ansi \
        --multi \
        --preview='bat --color=always {}' \
        --preview-window='right,60%,border-left' \
        --prompt='Files: '

    fd $fd_opts | fzf $fzf_opts | string join ' ' | read --local out; and commandline --insert $out
end

function _fuzzy_history
    set --local fzf_opts \
        --read0 \
        --preview='echo {}' \
        --preview-window='down,20%,border-up' \
        --prompt='History: '

    history --null | fzf $fzf_opts | read --null --local out; and commandline --replace $out
end
