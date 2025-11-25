# zsh-hop

A powerful Zsh plugin that brings vim-easymotion-style navigation to your command line. Jump to any character or word in your current command with visual labels, or quickly find and replace text - all with minimal keystrokes.

## Features

- **Smart Hop Navigation**: Intelligently jump to characters or words in your command line
  - Type a single character and wait (default 0.5 seconds) for automatic character search
  - Type multiple characters and press Enter to search for words/substrings
  - Configurable timeout for character detection
- **Find & Replace**: Interactive find and replace for the current command line with visual prompts
- **Visual Labels**: See labeled positions for each match - just type a label to jump there instantly
- **Customizable**: Configure colors, keybindings, timeout, and label characters to match your preferences
- **Oh-My-Zsh Compatible**: Installs seamlessly as an Oh-My-Zsh plugin or standalone

## Demo

### Character Hopping
```bash
# Before: cursor at the beginning
$ git commit -m "fix: update user authentication logic"
  ^

# Press Ctrl+F, type 'u' (waits 0.5s by default)
$ git commit -m "fix: update user authentication logic"
                     a     b    c

# Press 'c' to jump to the third 'u'
$ git commit -m "fix: update user authentication logic"
                                      ^
```

### Word Hopping
```bash
# Before: cursor at the beginning
$ docker run --name myapp --network bridge nginx
  ^

# Press Ctrl+F, type "net" and press Enter
$ docker run --name myapp --network bridge nginx
                           a

# Press 'a' to jump to "network"
$ docker run --name myapp --network bridge nginx
                           ^
```

## Installation

### Oh-My-Zsh

1. Clone this repository into Oh-My-Zsh's plugins directory:
   ```bash
   git clone https://github.com/thinkjk/zsh-hop.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-hop
   ```

2. Add `zsh-hop` to your plugins array in `~/.zshrc`:
   ```bash
   plugins=(... zsh-hop)
   ```

3. Restart your shell or reload your config:
   ```bash
   source ~/.zshrc
   ```

### Manual Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/thinkjk/zsh-hop.git ~/.zsh/zsh-hop
   ```

2. Source the plugin in your `~/.zshrc`:
   ```bash
   source ~/.zsh/zsh-hop/zsh-hop.plugin.zsh
   ```

3. Restart your shell or reload your config:
   ```bash
   source ~/.zshrc
   ```

### Using a Plugin Manager

#### Zinit
```bash
zinit light thinkjk/zsh-hop
```

#### Zplug
```bash
zplug "thinkjk/zsh-hop"
```

#### Antigen
```bash
antigen bundle thinkjk/zsh-hop
```

## Usage

### Smart Hop Navigation (Ctrl+F)

The hop feature intelligently handles both character and word searches:

1. Press `Ctrl+F` (default) while typing a command
2. Type what you're looking for:
   - **Single character**: Type one character and wait (default 0.5 seconds) for automatic search
   - **Word/substring**: Type multiple characters and press Enter
3. If multiple matches exist, labels (`a`, `s`, `d`, `f`, etc.) appear above each match
4. Type the label to jump your cursor to that position
5. Press `Esc` at any prompt to cancel

**Character Search Example:**
```bash
# Jump to a specific character
$ systemctl status nginx && grep error /var/log/nginx/error.log
# Press Ctrl+F, type 'e' (waits for timeout period)
# Labels appear above each 'e', press the label to jump there
```

**Word Search Example:**
```bash
# Jump to a specific word
$ docker run --name mycontainer --network bridge --restart always nginx
# Press Ctrl+F, type "rest", press Enter
# Jump directly to "restart" (or see labels if multiple matches)
```

### Find and Replace (Ctrl+G)

1. Press `Ctrl+G` (default) while typing a command
2. Type the text you want to find and press `Enter`
3. Type the replacement text and press `Enter`
4. All occurrences in the current line are replaced
5. Press `Esc` at any prompt to cancel

**Example:**
```bash
# Before
$ docker exec -it mycontainer bash

# Press Ctrl+G
# Find: mycontainer
# Replace with: production-app

# After
$ docker exec -it production-app bash
```

**Multiple Replacements Example:**
```bash
# Before
$ cp file1.txt file2.txt && mv file3.txt file4.txt

# Press Ctrl+G
# Find: .txt
# Replace with: .bak

# After
$ cp file1.bak file2.bak && mv file3.bak file4.bak
```

## Customization

Add these variables to your `~/.zshrc` **before** loading the plugin to customize behavior:

### Keybindings

```bash
# Change the hop keybinding (default: ^F = Ctrl+F)
ZSH_HOP_KEY="^J"  # Use Ctrl+J instead

# Change the find/replace keybinding (default: ^G = Ctrl+G)
ZSH_HOP_REPLACE_KEY="^R"  # Use Ctrl+R instead
```

**Common key notation:**
- `^F` = Ctrl+F
- `^J` = Ctrl+J
- `\ef` = Alt+F
- `\eh` = Alt+H

### Timeout Configuration

```bash
# Change the auto-submit timeout for single characters (default: 0.5 seconds)
ZSH_HOP_TIMEOUT=0.3   # Faster auto-submit (300ms)
ZSH_HOP_TIMEOUT=0.7   # Slower auto-submit (700ms)
ZSH_HOP_TIMEOUT=1.0   # Full second wait time
```

This controls how long the plugin waits after you type a single character before automatically searching. Lower values make single-character hops faster but may trigger before you finish typing a word.

### Colors

```bash
# Customize label color (default: bold yellow)
ZSH_HOP_LABEL_COLOR="\033[1;32m"  # Bold green

# Customize prompt color (default: bold cyan)
ZSH_HOP_PROMPT_COLOR="\033[1;35m"  # Bold magenta
```

**Color codes:**
- `\033[1;31m` - Bold Red
- `\033[1;32m` - Bold Green
- `\033[1;33m` - Bold Yellow
- `\033[1;34m` - Bold Blue
- `\033[1;35m` - Bold Magenta
- `\033[1;36m` - Bold Cyan

### Label Characters

```bash
# Customize the characters used for labels (default: home row first)
ZSH_HOP_LABELS="jklfdsauioewrghtyqpzxcvbnm"
```

### Example Configuration

```bash
# In your ~/.zshrc, before loading the plugin:

# Use Alt-based keybindings to avoid terminal conflicts
ZSH_HOP_KEY="\ef"           # Alt+F for hop
ZSH_HOP_REPLACE_KEY="\eh"   # Alt+H for replace

# Faster character detection for quick navigation
ZSH_HOP_TIMEOUT=0.3         # 300ms timeout

# Customize colors
ZSH_HOP_LABEL_COLOR="\033[1;32m"    # Green labels
ZSH_HOP_PROMPT_COLOR="\033[1;34m"   # Blue prompts

# Use home row keys for labels
ZSH_HOP_LABELS="asdfjkl;ghqweruiop"

# Then load the plugin
plugins=(... zsh-hop)
```

## Tips

- **Quick character jump**: For single characters, just type and wait - no Enter needed!
- **Precise word targeting**: Type the first few unique characters of a word for accurate jumping
- **Single match**: If there's only one match, you'll jump directly without needing to select a label
- **Escape anytime**: Press `Esc` during any prompt to cancel the operation
- **Backspace support**: All prompts support backspace for corrections
- **Case sensitive**: Searches are case-sensitive by default
- **Multiple replacements**: Find/replace replaces all occurrences in the current line
- **Label order**: Labels use home-row keys first (a,s,d,f,g,h,j,k,l) for easier typing

## Troubleshooting

### Keybinding conflicts

If `Ctrl+F` or `Ctrl+G` don't work:
- Some terminals map these differently or block them
- Try Alt-based bindings: `ZSH_HOP_KEY="\ef"` and `ZSH_HOP_REPLACE_KEY="\eh"`
- Or choose different keys entirely

### Labels not showing

If labels don't appear above characters:
- Ensure your terminal supports ANSI escape codes
- Try a different terminal emulator (most modern ones support this)

### Plugin not loading

- Verify the plugin is in the correct directory
- Check that it's listed in your `plugins=()` array (Oh-My-Zsh)
- Make sure you've reloaded your shell: `source ~/.zshrc`

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Inspiration

Inspired by:
- [vim-easymotion](https://github.com/easymotion/vim-easymotion) - The original character hopping plugin for Vim
- [hop.nvim](https://github.com/phaazon/hop.nvim) - Modern Neovim hopping
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - For excellent ZLE widget patterns

## See Also

- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - Fish-like autosuggestions
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - Syntax highlighting for Zsh
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder for command-line
