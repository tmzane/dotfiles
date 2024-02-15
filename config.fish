# set default editor
set --export EDITOR "nvim"

# brew: disable analytics
set --export HOMEBREW_NO_ANALYTICS 1
# brew: disable autoupdate
set --export HOMEBREW_NO_AUTO_UPDATE 1
# brew: disable install from API
set --export HOMEBREW_NO_INSTALL_FROM_API 1
# brew: automatically remove unused formula dependents
set --export HOMEBREW_AUTOREMOVE 1

# fzf: set default command and options
set --export FZF_DEFAULT_COMMAND "fd --hidden"
set --export FZF_DEFAULT_OPTS "--reverse --border"

if status is-interactive
    # fzf.fish: include hidden files when searching
    set fzf_fd_opts --hidden
    # fzf.fish: set custom key bindings
    fzf_configure_bindings --directory=\ef --git_log=\el --git_status=\es --history=\eh --processes=\ep --variables=\ev

    # enable vim mode
    fish_vi_key_bindings
    set fish_cursor_default block blink
    set fish_cursor_insert  line  blink

    # add git abbreviations
    abbr --add gw  "git switch"
    abbr --add gl  "git log --oneline"
    abbr --add gs  "git status --short"
    abbr --add gd  "git diff"
    abbr --add ga  "git add"
    abbr --add gc  "git commit"
    abbr --add gcm "git commit --message"
    abbr --add gp  "git push"
    abbr --add gpf "git push --force-with-lease"
    abbr --add gpl "git pull --rebase"
    abbr --add gst "git stash"

    # add misc abbreviations
    abbr --add \? "tldr"
    abbr --add \?\? "man"
    abbr --add py "python3"

    # replace builtin tools
    alias cat bat
    alias top htop
    alias vim nvim

    # add vpn aliases
    alias vpnon "sudo wg-quick up wg0"
    alias vpnoff "sudo wg-quick down wg0"

    # add "Make a dir and cd into it" command
    function md; set dir $argv[1]; mkdir -p $dir && cd $dir; end

    # add "Move to Trash" command
    function trash; mv $argv ~/.Trash; end

    # add "Open with QuickLook" command
    function ql; qlmanage -p $argv &> /dev/null; end
end
