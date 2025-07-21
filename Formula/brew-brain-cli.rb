class BrewBrainCli < Formula

  desc "Audit, document, and manage your Homebrew CLI arsenal with one meta-tool"
  homepage "https://github.com/raymonepping/brew_brain_cli"
  url "https://github.com/raymonepping/homebrew-brew-brain-cli/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "952f23049e4e5cb0d05f0c24a8df2c76ec3f61db34495afd915c309cd40d320e"
  license "MIT"
  version "1.1.0"

  depends_on "bash"
  depends_on "jq"

  def install
    bin.install "bin/brew_brain" => "brew_brain"
    share.install Dir["lib"], Dir["tpl"]
  end

  def caveats
    <<~EOS
      To get started, run:
        brew_brain --help

      This CLI helps audit, document, and version-manage your custom Homebrew CLI arsenal.

      Example usage:
        brew_brain --output markdown --output-file arsenal
        brew_brain checkup
    EOS
  end

  test do
    assert_match "brew_brain", shell_output("#{bin}/brew_brain --help")
  end
end
