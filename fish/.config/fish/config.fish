# set default editor to micro
set --global --export EDITOR micro

# disable homebrew analytics
set --global --export HOMEBREW_NO_ANALYTICS 1
# disable homebrew autoupdate
set --global --export HOMEBREW_NO_AUTO_UPDATE 1
# disable homebrew install from API
set --global --export HOMEBREW_NO_INSTALL_FROM_API 1

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
    abbr --add gs git status --short
    abbr --add gl git log --oneline
    abbr --add ga git add
    abbr --add gcm git commit --message
    abbr --add gw git switch

    # add misc abbreviations
    abbr --add p3 python3
    abbr --add \? tldr

    # add command aliases
    alias cat=bat
    alias top=htop
end
