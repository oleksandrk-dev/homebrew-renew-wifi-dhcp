class RenewWifiDhcp < Formula
  desc "Force Wi-Fi DHCP renew on wake via SleepWatcher (waits for SSID)"
  homepage "https://github.com/oleksandrk-dev/renew-wifi-dhcp"
  license "MIT"
  version "1.1.0"

  # --- Stable release (recommended for teammates) ---
  # After tagging, update these two:
  # url "https://github.com/oleksandrk-dev/renew-wifi-dhcp/archive/refs/tags/v1.1.0.tar.gz"
  # sha256 "REPLACE_WITH_SHA256"

  # --- Dev installs (optional) ---
  head "https://github.com/oleksandrk-dev/renew-wifi-dhcp.git", branch: "main"

  depends_on "sleepwatcher"

  def install
    # If repo provides renew-wifi-dhcp.sh, install it; else generate fallback.
    script = "renew-wifi-dhcp.sh"
    unless File.exist?(script)
      (buildpath/script).write <<~'SH'
        #!/bin/bash
        set -euo pipefail

        log() { printf '%s %s\n' "$(date '+%F %T')" "$*"; }

        # Find Wi-Fi device (en0/en1…); supports "Wi-Fi" and legacy "AirPort"
        wifi_dev=$(/usr/sbin/networksetup -listallhardwareports \
          | awk '/^Hardware Port: (Wi-Fi|AirPort)/{getline; print $2; exit}')

        if [[ -z "${wifi_dev:-}" ]]; then
          log "ERROR: Wi-Fi device not found"
          exit 2
        fi

        AIRPORT="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"

        get_ssid() {
          if [[ -x "$AIRPORT" ]]; then
            "$AIRPORT" -I 2>/dev/null | awk -F': *' '/ SSID/ {print $2; exit}'
          else
            local out
            out=$(/usr/sbin/networksetup -getairportnetwork "$wifi_dev" 2>/dev/null || true)
            [[ "$out" == "You are not associated with an AirPort network." ]] && out=""
            echo "$out" | sed 's/^Current Wi-Fi Network: //'
          fi
        }

        before_ip=$(ipconfig getifaddr "$wifi_dev" 2>/dev/null || true)
        log "device=$wifi_dev before_ip=${before_ip:-<none>} (waiting for Wi-Fi association)"

        # Wait up to 90s for association (SSID present)
        ssid=""
        for i in {1..90}; do
          ssid="$(get_ssid || true)"
          if [[ -n "$ssid" ]]; then
            log "associated ssid=$ssid (after ${i}s)"
            break
          fi
          sleep 1
        done

        if [[ -z "$ssid" ]]; then
          log "WARN: no SSID after 90s; skipping renew"
          exit 0
        fi

        # Force renew (BOOTP then DHCP ≈ release+renew); tolerate transient errors
        /usr/sbin/ipconfig set "$wifi_dev" BOOTP || true
        /usr/sbin/ipconfig set "$wifi_dev" DHCP  || true

        # Post-renew: wait up to 15s for IPv4
        after_ip=""
        for _ in {1..15}; do
          after_ip=$(ipconfig getifaddr "$wifi_dev" 2>/dev/null || true)
          [[ -n "${after_ip:-}" ]] && break
          sleep 1
        done

        log "after_ip=${after_ip:-<none>}"
        lease=$(ipconfig getpacket "$wifi_dev" 2>/dev/null | egrep 'yiaddr|server_identifier|lease_time' || true)
        [[ -n "$lease" ]] && log "lease:
$lease"

        exit 0
      SH
    end

    bin.install script => "renew-wifi-dhcp"
    chmod 0755, bin/"renew-wifi-dhcp"
    (var/"log").mkpath
  end

  service do
    # Wake-only hook
    run [Formula["sleepwatcher"].opt_sbin/"sleepwatcher",
         "-V",
         "-w", opt_bin/"renew-wifi-dhcp"]
    keep_alive true
    environment_variables PATH: std_service_path_env
    log_path var/"log/renew-wifi-dhcp.out"
    error_log_path var/"log/renew-wifi-dhcp.err"
  end

  test do
    assert_predicate bin/"renew-wifi-dhcp", :exist?
  end
end
