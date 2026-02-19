# fish-toolbox

A personal Fish configuration repository for syncing shell setup across multiple machines.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/DynamicCast03/fish-toolbox/main/install.sh | bash
```

The does the following:

1. Clones this repository into `~/fish-toolbox` (or runs `git pull` there if it already exists).
2. Appends this line to the end of `~/.config/fish/config.fish`:

```fish
source ~/fish-toolbox/fish-toolbox.fish
```