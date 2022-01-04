# typed: false
# frozen_string_literal: true

# This file was generated by GoReleaser. DO NOT EDIT.
class Vproxy < Formula
  desc "Zero-config virtual proxies with tls"
  homepage "https://github.com/jittering/vproxy"
  version "0.8"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jittering/vproxy/releases/download/v0.8/vproxy_0.8_Darwin_arm64.tar.gz"
      sha256 "4ad2541998dddd52169f61697ad6d84c622d20b3bc0d284e540652cd29798c97"

      def install
        bin.install "vproxy"

        bash_output = Utils.safe_popen_read("#{bin}/vproxy", "bash_completion")
        (bash_completion/"vproxy").write bash_output
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/jittering/vproxy/releases/download/v0.8/vproxy_0.8_Darwin_x86_64.tar.gz"
      sha256 "39df6c086616803c53176d97911f12ed9e0d74ab004a956d250b3b922aeef904"

      def install
        bin.install "vproxy"

        bash_output = Utils.safe_popen_read("#{bin}/vproxy", "bash_completion")
        (bash_completion/"vproxy").write bash_output
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/jittering/vproxy/releases/download/v0.8/vproxy_0.8_Linux_arm64.tar.gz"
      sha256 "978cfd129c9ccbef23267a4dbcfbd7e008b77c1b1d2c879a2ee6f35cd965328d"

      def install
        bin.install "vproxy"

        bash_output = Utils.safe_popen_read("#{bin}/vproxy", "bash_completion")
        (bash_completion/"vproxy").write bash_output
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/jittering/vproxy/releases/download/v0.8/vproxy_0.8_Linux_x86_64.tar.gz"
      sha256 "6e5955d3a4c450e65e7edd99fc2e9b3024689df0a28636743216f7123338036e"

      def install
        bin.install "vproxy"

        bash_output = Utils.safe_popen_read("#{bin}/vproxy", "bash_completion")
        (bash_completion/"vproxy").write bash_output
      end
    end
  end

  depends_on "mkcert"

  def post_install
    str = <<~EOF
      # Sample config file
      # All commented settings below are defaults

      # Enable verbose output
      #verbose = false

      [server]
      # Enable verbose output (for daemon only)
      #verbose = false

      # IP on which server will listen
      # To listen on all IPs, set listen = "0.0.0.0"
      #listen = "127.0.0.1"

      # Ports to listen on
      #http = 80
      #https = 443


      # CAROOT path
      caroot_path = "#{var}/vproxy/caroot"

      # Path where generated certificates should be stored
      cert_path = "#{var}/vproxy/cert"

      [client]
      # Enable verbose output (for client only)
      #verbose = false

      #host = "127.0.0.1"
      #http = 80

      # Use this in local config files, i.e., a .vproxy.conf file located in a
      # project folder
      #bind = ""
    EOF
    str = str.gsub(/^[\t ]+/, "") # trim leading spaces
    conf_file = "#{etc}/vproxy.conf"

    # always write new sample file
    File.open("#{conf_file}.sample", "w") do |f|
      f.puts str
    end

    # only create default conf if it doesn't already exist
    unless File.exist?(conf_file)
      File.open(conf_file, "w") do |f|
        f.puts str
      end
    end

    # setup var dir, if needed
    unless File.exist?("#{var}/vproxy")
      puts ohai_title("creating #{var}/vproxy")

      # Create/migrate caroot
      mkdir_p("#{var}/vproxy/caroot", mode: 0755)
      mkcert_caroot = `#{bin}/vproxy caroot --default`.strip
      pems = Dir.glob("#{mkcert_caroot}/*.pem")
      if pems.empty?
        puts ohai_title("caroot not found; create with: vaproxy caroot --create")
      else
        puts ohai_title("migrating caroot")
        cp(pems, "#{var}/vproxy/caroot")
      end

      # Create/migrate cert path
      puts ohai_title("created cert dir #{var}/vproxy/cert")
      mkdir_p("#{var}/vproxy/cert", mode: 0755)
      if File.exist?(old_cert_path)
        certs = Dir.glob("#{old_cert_path}/*.pem")
        puts ohai_title("migrating #{certs.size} certs")
        errs = 0
        certs.each do |cert|
          if File.readable?(cert)
            cp(cert, "#{var}/vproxy/cert")
          else
            errs += 1
          end
        end
        onoe("couldn't read #{errs} cert(s)") if errs.positive?
      end
    end

  end

  def caveats; <<~EOS
    To install your local root CA:
      $ vproxy caroot --create

    vproxy data is stored in #{var}/vproxy

    The local root CA is in #{var}/vproxy/caroot;
      certs will be stored in #{var}/vproxy/cert when generated.

    See vproxy documentation for more info
  EOS
  end

  plist_options :startup => false

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>KeepAlive</key>
    <dict>
      <key>SuccessfulExit</key>
      <false/>
    </dict>
    <key>Label</key>
    <string>#{plist_name}</string>
    <key>ProgramArguments</key>
    <array>
      <string>#{bin}/vproxy</string>
      <string>daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>#{var}</string>
    <key>StandardErrorPath</key>
    <string>#{var}/log/vproxy.log</string>
    <key>StandardOutPath</key>
    <string>#{var}/log/vproxy.log</string>
  </dict>
</plist>

  EOS
  end

  test do
    system "#{bin}/vproxy", "--version"
  end
end
