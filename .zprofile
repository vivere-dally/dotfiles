# Add Homebrew to login shells without assuming a CPU or operating system.
for _brew in \
    "$HOME/homebrew/bin/brew" \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x $_brew ]]; then
        eval "$("$_brew" shellenv)"
        break
    fi
done
unset _brew
