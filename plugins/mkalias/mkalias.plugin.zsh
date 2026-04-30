# hash-alias — Interactive hash -d manager for oh-my-zsh
# Usage: mkhash

# Enable cdable_vars so named directories work with 'cd <alias>'
setopt cdable_vars

function mkalias() {
    emulate -L zsh
    setopt extended_glob
    local target_dir alias_name zshrc_path
    zshrc_path="${ZDOTDIR:-$HOME}/.zshrc"

    echo "\n=== Create hash -d alias ==="

    # Step 1: Choose directory
    local choice
    read "choice?Alias current directory [$(pwd)]? [Y/n]: "

    if [[ "$choice" =~ ^[Nn]$ ]]; then
        target_dir=""
        echo "\nEnter directory path (use TAB for completion):"
        vared -p "> " target_dir
        target_dir="${~target_dir}"
        target_dir="${target_dir:A}"

        if [[ ! -d "$target_dir" ]]; then
            echo "Error: '$target_dir' is not a valid directory."
            return 1
        fi
    else
        target_dir="$(pwd)"
    fi

    # Step 2: Alias name
    read "alias_name?Enter alias name: "

    if [[ -z "$alias_name" ]]; then
        echo "Error: alias name cannot be empty."
        return 1
    fi

    if [[ "$alias_name" != [a-zA-Z0-9_-]## ]]; then
        echo "Error: alias name must contain only letters, numbers, hyphens, and underscores."
        return 1
    fi

    # Step 3: Conflict checks
    if (( ${+commands[$alias_name]} )); then
        echo "Error: '$alias_name' is an existing command."
        return 1
    fi

    if (( ${+builtins[$alias_name]} )); then
        echo "Error: '$alias_name' is a shell builtin."
        return 1
    fi

    if (( ${+aliases[$alias_name]} )); then
        echo "Error: '$alias_name' is an existing alias."
        return 1
    fi

    if (( ${+functions[$alias_name]} )); then
        echo "Error: '$alias_name' is an existing function."
        return 1
    fi

    if (( ${+nameddirs[$alias_name]} )); then
        echo "Error: '$alias_name' is already a named directory."
        return 1
    fi

    if grep -Eq "^\\s*hash\\s+-d\\s+${alias_name}=" "$zshrc_path" 2>/dev/null; then
        echo "Error: '$alias_name' is already defined in ${zshrc_path}."
        return 1
    fi

    # Step 4: Write to .zshrc and apply
    print "hash -d ${alias_name}=${(q)target_dir}" >> "$zshrc_path"
    echo "\nAdded to ${zshrc_path}:"
    echo "  hash -d ${alias_name}=${target_dir}"

    # Apply immediately without needing a new shell
    hash -d "${alias_name}"="${target_dir}"

    # Source .zshrc
    source "$zshrc_path"

    echo "\nDone. You can now use:"
    echo "  cd ${alias_name}"
    echo "  ~${alias_name}"
}
