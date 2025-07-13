# setup environment
set --export EDITOR                  nvim
set --export MANPAGER                nvim +Man!
set --export BAT_THEME               base16
# set --export BAT_THEME_LIGHT         OneHalfLight
# set --export BAT_THEME_DARK          OneHalfDark
set --export BROWSER                 librewolf
set --export CONTAINER_RUNNER        podman
set --export HOMEBREW_NO_ANALYTICS   1
set --export HOMEBREW_NO_AUTO_UPDATE 1
set --export FZF_DEFAULT_OPTS        "--tmux=100% --border=none --info=hidden"
set --export FZF_CTRL_T_OPTS         "--no-reverse --preview='bat --number --color=always {}' --preview-window=border-left"

# setup $PATH
fish_add_path --global --path --move /opt/homebrew/bin
fish_add_path --global --path --move ~/go/bin

# setup vi mode
fish_vi_key_bindings
set fish_cursor_default block blink
set fish_cursor_insert  line  blink

# setup keymaps
bind --mode default \cz "fg 2>/dev/null; commandline -f repaint-mode"
bind --mode insert  \cz "fg 2>/dev/null; commandline -f repaint-mode"

# setup prompt
starship init fish | source

# setup fzf
# https://github.com/junegunn/fzf
fzf --fish | source
# https://github.com/PatrickF1/fzf.fish
set fzf_fd_opts --hidden
fzf_configure_bindings --directory=\ef --git_log=\el --git_status=\es --history=\eh --processes=\ep --variables=\ev

# setup aliases
alias cat     bat
alias top     htop
alias vim     nvim
alias vpnup   "sudo wg-quick up wg0"
alias vpndown "sudo wg-quick down wg0"

# setup abbreviations
abbr --add ga  "git add"
abbr --add gap "git add --patch"
abbr --add gc  "git commit"
abbr --add gca "git commit --amend --no-edit"
abbr --add gcm "git commit --message"
abbr --add gd  "git diff HEAD"
abbr --add gf  "git fetch --all"
abbr --add gl  "git log --oneline"
abbr --add gp  "git push"
abbr --add gpf "git push --force-with-lease"
abbr --add gpl "git pull --rebase"
abbr --add gr  "git rebase"
abbr --add gri "git rebase --interactive"
abbr --add gs  "git status --short"
abbr --add gst "git stash"
abbr --add gw  "git switch"
abbr --add py  python3
