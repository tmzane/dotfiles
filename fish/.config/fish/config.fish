# set default editor
set --global --export EDITOR "subl --wait"

# disable homebrew analytics
set --global --export HOMEBREW_NO_ANALYTICS 1
# disable homebrew autoupdate
set --global --export HOMEBREW_NO_AUTO_UPDATE 1
# disable homebrew install from API
set --global --export HOMEBREW_NO_INSTALL_FROM_API 1
# tell homebrew to automatically remove unused formula dependents
set --global --export HOMEBREW_AUTOREMOVE 1

# set fzf default command and options
set --global --export FZF_DEFAULT_COMMAND "fd --hidden"
set --global --export FZF_DEFAULT_OPTS "--reverse --border --multi --marker=+"

# tell fzf.fish to include hidden files when searching
set --global fzf_fd_opts --hidden
# rebind fzf.fish default key bindings
# history: ctrl+opt+h; variables: ctrl+opt+v (use fish_key_reader)
fzf_configure_bindings --history=\e\b --variables=\e\cv

if status is-interactive
    # add git abbreviations
    abbr --add gw git switch
    abbr --add gl git log --oneline
    abbr --add gs git status --short
    abbr --add ga git add
    abbr --add gcm git commit --message
    abbr --add gp git push
    abbr --add gpf git push --force-with-lease

    # add misc abbreviations
    abbr --add \? tldr
    abbr --add py python3

    # replace builtin tools
    alias cat bat
    alias top htop
    alias mkdir "mkdir -p"

    # add "Move to Trash" command
    function trash; mv $argv ~/.Trash; end

    # add "Open with QuickLook" command
    function ql; qlmanage -p $argv > /dev/null; end
end
