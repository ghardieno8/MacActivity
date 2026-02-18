# Activity

CLI tool to manage memory on a Mac. View processes, monitor system memory, and clean up safe-to-close applications to reclaim RAM.

## Requirements

- macOS 13.0 or later
- Swift 5.9+

## Installation

### Build from source

```bash
# Clone the repository
git clone https://github.com/ghardieno8/MacActivity.git
cd MacActivity

# Build
swift build

# Or use the Makefile
make build
```

### Install globally

```bash
make install
```

This builds a release binary and copies it to `/usr/local/bin/activity`.

## Usage

| Command | Description |
|---------|-------------|
| `activity` or `activity monitor` | Interactive TUI for browsing and managing processes |
| `activity top` | Non-interactive process list (for pipes/scripts) |
| `activity stats` | System memory overview with pressure, usage breakdown |
| `activity kill <pid>` | Terminate a process by PID |
| `activity cleanup` | Interactive cleanup of safe-to-close processes |

### Examples

```bash
# Launch the interactive monitor (default)
activity

# View system memory stats
activity stats

# Process list (non-interactive)
activity top

# Clean up memory — show processes using ≥ 50 MB that are safe to close
activity cleanup

# Clean up with custom threshold (100 MB)
activity cleanup --threshold 100

# Dry run: see what would be killed without actually killing
activity cleanup --dry-run

# Skip confirmation prompts
activity cleanup --yes

# Kill a specific process
activity kill 12345
```

## License

Apache-2.0 — see [LICENSE](LICENSE) for details.
