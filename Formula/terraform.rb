class Terraform < Formula
  desc "Tool to build, change, and version infrastructure"
  homepage "https://www.terraform.io/"
  url "https://github.com/hashicorp/terraform/archive/v0.12.4.tar.gz"
  sha256 "e73dd1a80524e6f7b4c6b8b790d03f5626f73c140a3c4f25e966533011e39125"
  head "https://github.com/hashicorp/terraform.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "9776cccd10487d94a25d960b09ba6edb35a4cd836ed72a4a6d85aa8a57a10f39" => :mojave
    sha256 "600f2599a0309cf9dbb8f02f3fd7a5b9da0e1073cc493779ab373ae50013a65c" => :high_sierra
    sha256 "36a17d1799cd792c0fc2140c04549cdfbbfc7e941b16abaa1b9c8b6547fc304d" => :sierra
    sha256 "2aa7d02c5a2a4689cf768d6fb39a85b6c2dc87b81e0e5af2730e1f6b04026562" => :x86_64_linux
  end

  depends_on "go" => :build
  depends_on "gox" => :build

  conflicts_with "tfenv", :because => "tfenv symlinks terraform binaries"

  def install
    ENV["GOPATH"] = buildpath
    ENV["GO111MODULE"] = "on" unless OS.mac?
    ENV.prepend_create_path "PATH", buildpath/"bin"

    dir = buildpath/"src/github.com/hashicorp/terraform"
    dir.install buildpath.children - [buildpath/".brew_home"]

    cd dir do
      # v0.6.12 - source contains tests which fail if these environment variables are set locally.
      ENV.delete "AWS_ACCESS_KEY"
      ENV.delete "AWS_SECRET_KEY"

      os = OS.mac? ? "darwin" : "linux"
      ENV["XC_OS"] = os
      ENV["XC_ARCH"] = "amd64"
      # Tests fail to build on linux: FAIL: TestFmt_check
      # See https://github.com/Homebrew/linuxbrew-core/pull/13309
      system "make", "tools", *("test" if OS.mac?), "bin"

      bin.install "pkg/#{os}_amd64/terraform"
      prefix.install_metafiles
    end
  end

  test do
    minimal = testpath/"minimal.tf"
    minimal.write <<~EOS
      variable "aws_region" {
        default = "us-west-2"
      }

      variable "aws_amis" {
        default = {
          eu-west-1 = "ami-b1cf19c6"
          us-east-1 = "ami-de7ab6b6"
          us-west-1 = "ami-3f75767a"
          us-west-2 = "ami-21f78e11"
        }
      }

      # Specify the provider and access details
      provider "aws" {
        access_key = "this_is_a_fake_access"
        secret_key = "this_is_a_fake_secret"
        region     = var.aws_region
      }

      resource "aws_instance" "web" {
        instance_type = "m1.small"
        ami           = var.aws_amis[var.aws_region]
        count         = 4
      }
    EOS
    system "#{bin}/terraform", "init"
    system "#{bin}/terraform", "graph"
  end
end
