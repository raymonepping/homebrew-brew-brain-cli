class BrewBrainCli < Formula

  desc "Audit, document, and manage your Homebrew CLI arsenal with one meta-tool"
  homepage "https://github.com/raymonepping/brew_brain_cli"
  url "https://github.com/raymonepping/homebrew-brew-brain-cli/archive/refs/tags/v1.0.3.tar.gz"
  sha256 "66fef7ba704d4f69a00ee1e499e61dd9e2b1da7fd3eec1cde3214abe0f662a59"
  license "MIT"
  version "1.0.3"

  depends_on "bash"
  depends_on "jq"

  def install
    bin.install "bin/brew_brain" => "brew_brain"
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
