class ChameleonUltraCli < Formula
  include Language::Python::Virtualenv

  desc "CLI client for ChameleonUltra NFC/RFID emulator"
  homepage "https://github.com/kroleg/ChameleonUltra"
  url "https://github.com/kroleg/ChameleonUltra.git",
    tag:      "v2.1.1",
    revision: "4539122a180d38d5f7e383c513c0f643c39a1841"
  license "GPL-3.0-only"

  depends_on "cmake" => :build
  depends_on "openssl@3"
  depends_on "python@3.12"

  resource "pyserial" do
    url "https://files.pythonhosted.org/packages/1e/7d/ae3f0a63f41e4d2f6cb66a5b57197850f919f59e558159a4dd3a818f5082/pyserial-3.5.tar.gz"
    sha256 "3c77e014170dfffbd816e6ffc205e9842efb10be9f58ec16d3e8675b4925cddb"
  end

  resource "prompt-toolkit" do
    url "https://files.pythonhosted.org/packages/9a/02/76cadde6135986dc1e82e2928f35ebeb5a1af805e2527fe466285593a2ba/prompt_toolkit-3.0.39.tar.gz"
    sha256 "04505ade687dc26dc4284b1ad19a83be2f2afe83e7a828ace0c72f3a1df72aac"
  end

  resource "wcwidth" do
    url "https://files.pythonhosted.org/packages/6c/63/53559446a878410fc5a5974feb13d31d78d752eb18aeba59c7fef1af7598/wcwidth-0.2.13.tar.gz"
    sha256 "72ea0c06399eb286d978fdedb6923a9eb47e1c486ce63e9b4e64fc18303972b5"
  end

  resource "colorama" do
    url "https://files.pythonhosted.org/packages/d8/53/6f443c9a4a8358a93a6792e2acffb9d9d5cb0a5cfd8802644b7b1c9a02e4/colorama-0.4.6.tar.gz"
    sha256 "08695f5cb7ed6e0531a20572697297273c47b8cae5a63ffc6d6ed5c201be6e44"
  end

  def install
    # Build native C tools — CMake outputs to software/script/bin/
    cd "software/src" do
      mkdir "build" do
        system "cmake", "..", *std_cmake_args,
               "-DCMAKE_BUILD_TYPE=Release"
        system "cmake", "--build", ".", "--config", "Release"
      end
    end

    # Set up Python virtualenv and install dependencies
    venv = virtualenv_create(libexec, "python3.12")
    venv.pip_install resources

    # Install Python scripts and native binaries into libexec/script/
    script_dir = libexec/"script"
    script_dir.install Dir["software/script/*.py"]
    (script_dir/"bin").install Dir["software/script/bin/*"]

    # Create wrapper script
    (bin/"chameleon-ultra-cli").write <<~SH
      #!/bin/bash
      exec "#{libexec}/bin/python3.12" "#{script_dir}/chameleon_cli_main.py" "$@"
    SH
    (bin/"chameleon-ultra-cli").chmod 0755
  end

  test do
    assert_predicate bin/"chameleon-ultra-cli", :executable?
  end
end
