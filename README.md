# Homebrew Tap: renew-wifi-dhcp

Automatically renew Wi-Fi DHCP lease on macOS wake to fix connectivity issues.

## Installation

```bash
# Add the tap
brew tap oleksandrk-dev/renew-wifi-dhcp

# Install the formula
brew install renew-wifi-dhcp

# Start the service
brew services start renew-wifi-dhcp
```

## What it does

This tool solves the issue where macOS Wi-Fi doesn't work properly after waking from sleep due to DHCP lease problems. It:

1. Monitors system wake events using SleepWatcher
2. Waits for Wi-Fi to associate with a network (up to 90 seconds)
3. Forces a DHCP lease renewal
4. Verifies connectivity and logs the results

## Usage

Once installed and started as a service, it runs automatically in the background. No manual intervention needed!

### View logs

```bash
# Output logs
tail -f /opt/homebrew/var/log/renew-wifi-dhcp.out

# Error logs
tail -f /opt/homebrew/var/log/renew-wifi-dhcp.err
```

### Stop the service

```bash
brew services stop renew-wifi-dhcp
```

### Uninstall

```bash
brew services stop renew-wifi-dhcp
brew uninstall renew-wifi-dhcp
brew untap oleksandrk-dev/renew-wifi-dhcp
```

## Requirements

- macOS
- Homebrew
- SleepWatcher (automatically installed as a dependency)

## License

MIT

