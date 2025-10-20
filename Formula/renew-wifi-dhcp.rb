class RenewWifiDhcp < Formula
  desc "Force Wi-Fi DHCP renew on wake via SleepWatcher (waits for SSID)"
  homepage "https://github.com/oleksandrk-dev/renew-wifi-dhcp"
  license "MIT"
  url "https://github.com/oleksandrk-dev/renew-wifi-dhcp/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "bb24f6ede20c90e60f8b85482880284edf2bb2adb5ce571a128398152009ec7d"
  head "https://github.com/oleksandrk-dev/renew-wifi-dhcp.git", branch: "main"

  depends_on "sleepwatcher"

  def install
    bin.install "renew-wifi-dhcp.sh" => "renew-wifi-dhcp"
    chmod 0755, bin/"renew-wifi-dhcp"
    (var/"log").mkpath
  end

  service do
    # Wake-only hook - requires root for ipconfig commands
    run [Formula["sleepwatcher"].opt_sbin/"sleepwatcher",
         "-V",
         "-w", opt_bin/"renew-wifi-dhcp"]
    require_root true
    keep_alive true
    environment_variables PATH: std_service_path_env
    log_path var/"log/renew-wifi-dhcp.out"
    error_log_path var/"log/renew-wifi-dhcp.err"
  end

  test do
    assert_predicate bin/"renew-wifi-dhcp", :exist?
  end
end
