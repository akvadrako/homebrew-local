require 'formula'

class Rpm < Formula
  url 'http://rpm.org/releases/rpm-4.10.x/rpm-4.10.0.tar.bz2'
  homepage 'http://www.rpm.org/'
  md5 '6531fa74f06df0feee774688538241e8'

  depends_on 'nss'
  depends_on 'nspr'
  depends_on 'libmagic'
  depends_on 'popt'
  depends_on 'lua'
  depends_on 'berkeley-db'

  def patches
    DATA
  end

  def install
    # Note - MacPorts also builds without optimizations. This seems to fix several
    # random crashes
    ENV.append 'CPPFLAGS', "-I#{HOMEBREW_PREFIX}/include/nss -I#{HOMEBREW_PREFIX}/include/nspr"
    ENV.append 'CFLAGS', "-O0 -g3"
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}", "--with-external-db", "--sysconfdir=#{HOMEBREW_PREFIX}/etc", "--disable-optimize", "--without-javaglue", "--without-apidocs", "--enable-python", "--localstatedir=#{HOMEBREW_PREFIX}/var"
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

