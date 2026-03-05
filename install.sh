#!/usr/bin/env bash
set -euo pipefail

repo_url="${REPO_URL:-https://github.com/DynamicCast03/fish-toolbox.git}"
target_dir="$HOME/fish-toolbox"
config_file="$HOME/.config/fish/config.fish"
source_line="source ~/fish-toolbox/fish-toolbox.fish"

echo "[fish-toolbox] repo: $repo_url"
echo "[fish-toolbox] target: $target_dir"

if [ -d "$target_dir/.git" ]; then
    echo "[fish-toolbox] existing repo detected, pulling latest changes..."
    git -C "$target_dir" pull --ff-only
else
    echo "[fish-toolbox] cloning repository..."
    git clone "$repo_url" "$target_dir"
fi

echo "[fish-toolbox] installing fisher and bass..."
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher && fisher install edc/bass"

echo "[fish-toolbox] ensuring fish config exists..."
mkdir -p "$(dirname "$config_file")"
touch "$config_file"

last_non_empty_line="$(awk 'NF { last = $0 } END { print last }' "$config_file")"
if [ "$last_non_empty_line" = "$source_line" ]; then
    echo "[fish-toolbox] source line already at file end, skip update."
else
    if [ -s "$config_file" ]; then
        printf '\n%s\n' "$source_line" >> "$config_file"
    else
        printf '%s\n' "$source_line" >> "$config_file"
    fi
    echo "[fish-toolbox] source line appended to $config_file"
fi

echo "[fish-toolbox] done."
