class Modules < Formula
  desc "Dynamic modification of a user's environment via modulefiles"
  homepage "https://modules.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/modules/Modules/modules-4.2.3/modules-4.2.3.tar.bz2"
  sha256 "83a4afdd3784278cb86aa3fbf82bcda8fea46b12fae616d865cfe7e8d357e4ac"

  bottle do
    cellar :any_skip_relocation
    sha256 "6704ca06536aaa7b15d6f4b7a44a697e5e264585d0725f9a7a2add96699e420e" => :mojave
    sha256 "d3f08b74c54724430e0bf0b9bbbff9c1eeb1c22b98b14c9d4d3221c8ae2d4161" => :high_sierra
    sha256 "6c639f39e28ad98625f59540125fda9e86f4241ecdaa1d957b5f2ec413d014b0" => :sierra
    sha256 "4d9af8225dfc37ff56fad29fadfac56fe0ccfe846efb6fd27ec6ad6898259ddf" => :x86_64_linux
  end

  unless OS.mac?
    depends_on "tcl-tk"
    depends_on "less"
  end

  def install
    tcl = OS.mac? ? "#{MacOS.sdk_path}/System/Library/Frameworks/Tcl.framework" : Formula["tcl-tk"].opt_lib
    with_tclsh = OS.mac? ? "" : "--with-tclsh=#{Formula["tcl-tk"].opt_bin}/tclsh"
    with_pager = OS.mac? ? "" : "--with-pager=#{Formula["less"].opt_bin}/less"

    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
      --datarootdir=#{share}
      --with-tcl=#{tcl}
      #{with_tclsh}
      #{with_pager}
      --without-x
    ]
    system "./configure", *args
    system "make", "install"
  end

  def caveats; <<~EOS
    To activate modules, add the following at the end of your .zshrc:
      source #{opt_prefix}/init/zsh
    You will also need to reload your .zshrc:
      source ~/.zshrc
  EOS
  end

  test do
    assert_match "restore", shell_output("#{bin}/envml --help")
    if OS.mac?
      output = shell_output("zsh -c 'source #{prefix}/init/zsh; module' 2>&1")
    else
      output = shell_output("sh -c '. #{prefix}/init/sh; module' 2>&1")
    end
    assert_match version.to_s, output
  end
end
