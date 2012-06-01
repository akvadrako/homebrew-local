#
# RPM5.4 looks nicer - see the macports file:
# 
# https://trac.macports.org/browser/trunk/dports/sysutils/rpm54/Portfile
#
require 'formula'

class RpmDownloadStrategy < CurlDownloadStrategy
  def stage
    safe_system "rpm2cpio <#{@tarball_path} | cpio -dvim"
    safe_system "tar -xzf rpm-5.4.9.tar.gz"
    Dir.chdir "rpm-5.4.9"
  end
end

class Rpm < Formula
  url 'http://rpm5.org/files/rpm/rpm-5.4/rpm-5.4.9-0.20120508.src.rpm'
  homepage 'http://www.rpm5.org/'
  md5 '60d56ace884340c1b3fcac6a1d58e768'

  depends_on 'nss'
  depends_on 'nspr'
  depends_on 'libmagic'
  depends_on 'popt'
  depends_on 'lua'
  depends_on 'berkeley-db'
  # depends_on 'expat'
  # depends_on 'neon'
  # depends_on 'beecrypt'
  # depends_on 'gettext'
  # depends_on 'libtool'
  # depends_on 'xar'
  # depends_on 'xz'
  # depends_on 'ossp-uuid'
  depends_on 'rpm2cpio'

  fails_with :clang do
    build 318
  end

  def patches
    # DATA
  end
  
  def download_strategy
    RpmDownloadStrategy
  end

  def install
    # Note - MacPorts also builds without optimizations. This seems to fix several
    # random crashes
    # export CPPFLAGS="$(pkg-config nss --cflags)"
    #ENV.append 'CPPFLAGS', "-I#{HOMEBREW_PREFIX}/include/nss -I#{HOMEBREW_PREFIX}/include/nspr"
    ENV.append 'CFLAGS', "-O0 -g3 -m32"
    args = %W[
        --prefix=#{prefix}
        --with-beecrypt=external 
        --without-apidocs 
        --with-python=2.6
        --disable-openmp
        --with-lua=internal
        --with-syck=internal
    ]
    old_args = %W[
        --disable-optimize
        --sysconfdir=#{HOMEBREW_PREFIX}/etc
        --disable-dependency-tracking
        --with-external-db
        --without-javaglue
        --without-apidocs
        --enable-python
        --localstatedir=#{HOMEBREW_PREFIX}/var"
    ]
    more_args = %W[
        --disable-nls 
        --without-included-gettext
        --with-libintl-prefix=#{HOMEBREW_PREFIX} 
        --with-libiconv-prefix=#{HOMEBREW_PREFIX}
        --mandir=#{HOMEBREW_PREFIX}/share/man 
        --infodir=#{HOMEBREW_PREFIX}/share/info
        --with-perl 
        --with-sqlite 
        --with-db=external
        --with-neon=external 
        --with-popt=external
        --with-xar=external 
        --with-xz=external 
        --with-pcre=external 
        --with-uuid=external
        --sysconfdir=#{HOMEBREW_PREFIX}/etc 
        --with-path-cfg=#{HOMEBREW_PREFIX}/etc/rpm
    ]
    system "./configure", *args
    system "make"
    system "make install"
  end
end

__END__
diff -ur rpm-4.10.0/lib/poptALL.c rpm-4.10.0-me/lib/poptALL.c
--- rpm-4.10.0/lib/poptALL.c	2012-03-20 09:07:25.000000000 +0100
+++ rpm-4.10.0-me/lib/poptALL.c	2012-05-29 15:43:55.000000000 +0200
@@ -234,7 +234,7 @@
     int rc;
     const char *ctx, *execPath;
 
-    setprogname(argv[0]);       /* Retrofit glibc __progname */
+    xsetprogname(argv[0]);       /* Retrofit glibc __progname */
 
     /* XXX glibc churn sanity */
     if (__progname == NULL) {
diff -ur rpm-4.10.0/misc/glob.c rpm-4.10.0-me/misc/glob.c
--- rpm-4.10.0/misc/glob.c	2012-03-20 09:07:25.000000000 +0100
+++ rpm-4.10.0-me/misc/glob.c	2012-05-29 15:30:07.000000000 +0200
@@ -944,6 +944,11 @@
 }
 # ifdef _LIBC
 weak_alias (__glob_pattern_p, glob_pattern_p)
+# else
+int glob_pattern_p (__const char *__pattern, int __quote)
+{
+    return __glob_pattern_p(__pattern, __quote);
+}
 # endif
 #endif
 
diff -ur rpm-4.10.0/rpm2cpio.c rpm-4.10.0-me/rpm2cpio.c
--- rpm-4.10.0/rpm2cpio.c	2012-03-20 09:07:25.000000000 +0100
+++ rpm-4.10.0-me/rpm2cpio.c	2012-05-29 15:44:44.000000000 +0200
@@ -21,7 +21,7 @@
     off_t payload_size;
     FD_t gzdi;
     
-    setprogname(argv[0]);	/* Retrofit glibc __progname */
+    xsetprogname(argv[0]);	/* Retrofit glibc __progname */
     rpmReadConfigFiles(NULL, NULL);
     if (argc == 1)
 	fdi = fdDup(STDIN_FILENO);
diff -ur rpm-4.10.0/system.h rpm-4.10.0-me/system.h
--- rpm-4.10.0/system.h	2012-03-20 09:07:25.000000000 +0100
+++ rpm-4.10.0-me/system.h	2012-05-29 15:45:36.000000000 +0200
@@ -21,6 +21,7 @@
 #ifdef __APPLE__
 #include <crt_externs.h>
 #define environ (*_NSGetEnviron())
+#define fdatasync fsync
 #else
 extern char ** environ;
 #endif /* __APPLE__ */
@@ -114,10 +115,10 @@
 #if __GLIBC_MINOR__ >= 1
 #define	__progname	__assert_program_name
 #endif
-#define	setprogname(pn)
+#define	xsetprogname(pn)
 #else
 #define	__progname	program_name
-#define	setprogname(pn)	\
+#define	xsetprogname(pn)	\
   { if ((__progname = strrchr(pn, '/')) != NULL) __progname++; \
     else __progname = pn;		\
   }
diff --git a/rpmqv.c b/rpmqv.c
index da5f2ca..678af3e 100644
--- a/rpmqv.c
+++ b/rpmqv.c
@@ -1,5 +1,5 @@
 #include "system.h"
-const char *__progname;
+const char *__progname = "rpm";
 
 #include <rpm/rpmcli.h>
 #include <rpm/rpmlib.h>                        /* RPMSIGTAG, rpmReadPackageFile .. */

