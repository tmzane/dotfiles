# set default editor to micro
set --global --export EDITOR micro

# disable homebrew analytics
set --global --export HOMEBREW_NO_ANALYTICS 1
# disable homebrew autoupdate
set --global --export HOMEBREW_NO_AUTO_UPDATE 1
# disable homebrew install from API
set --global --export HOMEBREW_NO_INSTALL_FROM_API 1

# tell fzf.fish to include hidden files when searching
set --global fzf_fd_opts --hidden --exclude=.git
# rebind fzf.fish default key bindings
fzf_configure_bindings --history=\e\b --variables=\e\cv

if status is-interactive
    # commands to run in interactive sessions
end
