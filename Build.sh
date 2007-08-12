#!/bin/sh
# $MirOS: src/bin/mksh/Build.sh,v 1.251 2007/08/12 13:42:19 tg Exp $
#-
# Environment used: CC CFLAGS CPPFLAGS LDFLAGS LIBS NOWARN NROFF TARGET_OS
# CPPFLAGS recognised:	MKSH_SMALL MKSH_ASSUME_UTF8 MKSH_NEED_MKNOD MKSH_NOPWNAM
#			MKSH_NOVI

v() {
	$e "$*"
	eval "$@"
}

vq() {
	eval "$@"
}

if test -d /usr/xpg4/bin/. >/dev/null 2>&1; then
	# Solaris: some of the tools have weird behaviour, use portable ones
	PATH=/usr/xpg4/bin:$PATH
	export PATH
fi

if test -n "${ZSH_VERSION+x}" && (emulate sh) >/dev/null 2>&1; then
	emulate sh
	NULLCMD=:
fi

allu=QWERTYUIOPASDFGHJKLZXCVBNM
alll=qwertyuiopasdfghjklzxcvbnm
alln=0123456789
alls=______________________________________________________________
nl='
'
tcfn=no
bi=
ui=
ao=
fx=
me=`basename "$0"`
orig_CFLAGS=$CFLAGS

if test -t 1; then
	bi='[1m'
	ui='[4m'
	ao='[0m'
fi

upper() {
	echo :"$@" | sed 's/^://' | tr $alll $allu
}

# clean up after ac_testrun()
ac_testdone() {
	eval HAVE_$fu=$fv
	fr=no
	test 0 = $fv || fr=yes
	$e "$bi==> $fd...$ao $ui$fr$ao$fx"
	fx=
}

# ac_cache label: sets f, fu, fv?=0
ac_cache() {
	f=$1
	fu=`upper $f`
	eval fv=\$HAVE_$fu
	case $fv in
	0|1)
		fx=' (cached)'
		return 0
		;;
	esac
	fv=0
	return 1
}

# ac_testinit label [!] checkif[!]0 [setlabelifcheckis[!]0] useroutput
# returns 1 if value was cached/implied, 0 otherwise: call ac_testdone
ac_testinit() {
	if ac_cache $1; then
		test x"$2" = x"!" && shift
		test x"$2" = x"" || shift
		fd=$3
		ac_testdone
		return 1
	fi
	fc=0
	if test x"$2" = x""; then
		ft=1
	else
		if test x"$2" = x"!"; then
			fc=1
			shift
		fi
		eval ft=\$HAVE_`upper $2`
		shift
	fi
	fd=$3
	test x"$fd" = x"" && fd=$f
	if test $fc = "$ft"; then
		fv=$2
		fx=' (implied)'
		ac_testdone
		return 1
	fi
	$e ... $fd
	return 0
}

# pipe .c | ac_test[n] [!] label [!] checkif[!]0 [setlabelifcheckis[!]0] useroutput
ac_testn() {
	if test x"$1" = x"!"; then
		fr=1
		shift
	else
		fr=0
	fi
	ac_testinit "$@" || return
	cat >scn.c
	eval 'v "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN scn.c $LIBS" 2>&'$h | \
	    sed 's/^/] /'
	test x"$tcfn" = x"no" && test -f a.out && tcfn=a.out
	test x"$tcfn" = x"no" && test -f a.exe && tcfn=a.exe
	if test -f $tcfn; then
		test $fr = 1 || fv=1
	else
		test $fr = 0 || fv=1
	fi
	rm -f scn.c scn.o $tcfn
	ac_testdone
}

ac_cppflags() {
	test x"$1" = x"" || fu=$1
	fv=$2
	test x"$2" = x"" && eval fv=\$HAVE_$fu
	CPPFLAGS="$CPPFLAGS -DHAVE_$fu=$fv"
}

ac_test() {
	ac_testn "$@"
	ac_cppflags
}

# ac_flags [-] add varname flags [text]
ac_flags() {
	if test x"$1" = x"-"; then
		shift
		hf=1
	else
		hf=0
	fi
	fa=$1
	vn=$2
	f=$3
	ft=$4
	test x"$ft" = x"" && ft="if $f can be used"
	save_CFLAGS=$CFLAGS
	CFLAGS="$CFLAGS $f"
	if test $hf = 1; then
		ac_testn can_$vn '' "$ft"
	else
		ac_testn can_$vn '' "$ft" <<-'EOF'
			int main(void) { return (0); }
		EOF
	fi
	eval fv=\$HAVE_CAN_`upper $vn`
	test 11 = $fa$fv || CFLAGS=$save_CFLAGS
}

# ac_header header [prereq ...]
ac_header() {
	hf=$1; shift
	hv=`echo "$hf" | tr -d '\012\015' | tr -c $alll$allu$alln $alls`
	for i
	do
		echo "#include <$i>" >>x
	done
	echo "#include <$hf>" >>x
	echo 'int main(void) { return (0); }' >>x
	ac_test "$hv" "" "<$hf>" <x
	rm -f x
}

addsrcs() {
	eval i=\$$1
	test 0 = $i && case " $SRCS " in
	*\ $2\ *)	;;
	*)		SRCS="$SRCS $2" ;;
	esac
}


if test -d mksh || test -d mksh.exe; then
	echo "$me: Error: ./mksh is a directory!" >&2
	exit 1
fi
rm -f a.exe a.out *core crypt.exp lft mksh mksh.cat1 mksh.exe no *.o \
    scn.c signames.inc test.sh x

: ${CC=cc} ${NROFF=nroff}
curdir=`pwd` srcdir=`dirname "$0"` check_categories=pdksh

e=echo
h=1
r=0
eq=0

for i
do
	case $i in
	-Q)
		eq=1
		;;
	-q)
		e=:
		h=-
		;;
	-r)
		r=1
		;;
	*)
		echo "$me: Unknown option '$i'!" >&2
		exit 1
		;;
	esac
done

SRCS="alloc.c edit.c eval.c exec.c expr.c funcs.c histrap.c"
SRCS="$SRCS jobs.c lex.c main.c misc.c shf.c syn.c tree.c var.c"

test $r = 0 && echo | $NROFF -v 2>&1 | grep GNU >/dev/null 2>&1 && \
    NROFF="$NROFF -c"
if test x"$srcdir" = x"."; then
	CPPFLAGS="-I. $CPPFLAGS"
else
	CPPFLAGS="-I. -I'$srcdir' $CPPFLAGS"
fi


test x"$TARGET_OS" = x"" && TARGET_OS=`uname -s 2>/dev/null || uname`
warn=
ccpc=-Wc,
ccpl=-Wl,
tsts=
case $TARGET_OS in
AIX)
	if test x"$LDFLAGS" = x""; then
		LDFLAGS="${ccpl}-bI:crypt.exp"
		cat >crypt.exp <<-EOF
			#!
			__crypt_r
			__encrypt_r
			__setkey_r
		EOF
	fi
	: ${LIBS='-lcrypt'}
	;;
CYGWIN*)
	;;
Darwin)
	;;
DragonFly)
	;;
FreeBSD)
	;;
GNU)
	CPPFLAGS="$CPPFLAGS -D_GNU_SOURCE"
	;;
GNU/kFreeBSD)
	CPPFLAGS="$CPPFLAGS -D_GNU_SOURCE"
	;;
HP-UX)
	;;
Interix)
	ccpc='-X '
	ccpl='-Y '
	CPPFLAGS="$CPPFLAGS -D_ALL_SOURCE"
	: ${LIBS='-lcrypt'}
	;;
Linux)
	CPPFLAGS="$CPPFLAGS -D_GNU_SOURCE"
	: ${HAVE_REVOKE=0}
	;;
MidnightBSD)
	;;
Minix)
	CPPFLAGS="$CPPFLAGS -D_MINIX -D_POSIX_SOURCE"
	warn=' and will currently not work'
#	warn=" but might work with the GNU tools"
#	warn="$warn${nl}but not with ACK - /usr/bin/cc - yet)"
	;;
MirBSD)
	;;
NetBSD)
	;;
OpenBSD)
	;;
Plan9)
	CPPFLAGS="$CPPFLAGS -D_POSIX_SOURCE -D_LIMITS_EXTENSION"
	CPPFLAGS="$CPPFLAGS -D_BSD_EXTENSION -D_SUSV2_SOURCE -D__Plan9__"
	warn=' and will currently not work'
	;;
PW32*)
	cat >stdint.h <<-'EOF'
		typedef signed char int8_t;
		typedef signed short int16_t;
		typedef signed int int32_t;
		typedef signed long long int64_t;
		typedef unsigned char uint8_t;
		typedef unsigned short uint16_t;
		typedef unsigned int uint32_t;
		typedef unsigned long long uint64_t;
		typedef unsigned char u_char;
		typedef unsigned int u_int;
		typedef unsigned long u_long;
	EOF
	HAVE_SIG_T=0
	CPPFLAGS="$CPPFLAGS -Dsig_t=nosig_t"
	warn=' and will currently not work'
	# missing: killpg() getrlimit()
	;;
SunOS)
	CPPFLAGS="$CPPFLAGS -D_BSD_SOURCE -D__EXTENSIONS__"
	;;
UWIN*)
	ccpc='-Yc,'
	ccpl='-Yl,'
	tsts=" 3<>/dev/tty"
	warn="; it will compile, but the target"
	warn="$warn${nl}platform itself is very flakey/unreliable"
	;;
*)
	warn='; it may or may not work'
	;;
esac

if test -n "$warn"; then
	echo "Warning: mksh has not yet been ported to or tested on your" >&2
	echo "operating system '$TARGET_OS'$warn. If you can provide" >&2
	echo "a shell account to the developer, this may improve; please" >&2
	echo "drop us a success or failure notice or even send in diffs." >&2
fi


#
# Begin of mirtoconf checks
#
$e $bi$me: Scanning for functions... please ignore any errors.$ao

#
# Compiler: which one?
#
# notes:
# – ICC defines __GNUC__ too
# – GCC defines __hpux too
CPP="$CC -E"
$e ... which compiler we seem to use
cat >scn.c <<-'EOF'
	#if defined(__ICC) || defined(__INTEL_COMPILER)
	ct=icc
	#elif defined(__xlC__)
	ct=xlc
	#elif defined(__SUNPRO_C)
	ct=sunpro
	#elif defined(__BORLANDC__)
	ct=bcc
	#elif defined(__DMC__)
	ct=dmc
	#elif defined(_MSC_VER)
	ct=msc
	#elif defined(__TenDRA__)
	ct=tendra
	#elif defined(__TINYC__)
	ct=tcc
	#elif defined(__GNUC__)
	ct=gcc
	#elif defined(__hpux)
	ct=hpcc
	#else
	ct=unknown
	#endif
EOF
ct=unknown
eval 'v "$CPP scn.c | grep ct= | tr -d \\\\015 >x" 2>&'$h | sed 's/^/] /'
test $h = 1 && sed 's/^/[ /' x
eval `cat x`
rm -f x
case $ct in
bcc|dmc|gcc|hpcc|icc|msc|sunpro|tcc|tendra|xlc) ;;
*) ct=unknown ;;
esac
$e "$bi==> which compiler we seem to use...$ao $ui$ct$ao"
rm -f scn.c scn.o

case $TARGET_OS in
HP-UX)
	case $ct:`uname -m` in
	gcc:ia64) : ${CFLAGS='-mlp64'} ;;
	hpcc:ia64) : ${CFLAGS='+DD64'} ;;
	esac
	;;
esac

#
# Compiler: works as-is, with -Wno-error and -Werror
#
save_NOWARN=$NOWARN
NOWARN=
DOWARN=
ac_flags 0 compiler_works '' 'if the compiler works'
test 1 = $HAVE_CAN_COMPILER_WORKS || exit 1
HAVE_COMPILER_KNOWN=0
test $ct = unknown || HAVE_COMPILER_KNOWN=1
ac_testn couldbe_tcc '!' compiler_known 0 'if this could be tcc' <<-EOF
	#ifndef __TINYC__
	#error No, cannot be tcc.
	#endif
	int main(void) { return (0); }
EOF
if test $HAVE_COULDBE_TCC = 1; then
	ct=tcc
	CPP='cpp -D__TINYC__'
fi
ac_testn compiler_fails '' 'if the compiler does not fail correctly' <<-EOF
	int main(void) { return (thiswillneverbedefinedIhope()); }
EOF
if test $HAVE_COMPILER_FAILS = 1; then
	save_CFLAGS=$CFLAGS
	if test $ct = dmc; then
		CFLAGS="$CFLAGS ${ccpl}/DELEXECUTABLE"
		ac_testn can_delexe compiler_fails 0 'for the /DELEXECUTABLE linker option' <<-EOF
			int main(void) { return (0); }
		EOF
		test $HAVE_CAN_DELEXE = 1 || CFLAGS=$save_CFLAGS
	else
		CFLAGS="$CFLAGS ${ccpl}+k"
		ac_testn can_plusk compiler_fails 0 'for the +k linker option' <<-EOF
			int main(void) { return (0); }
		EOF
		test $HAVE_CAN_PLUSK = 1 || CFLAGS=$save_CFLAGS
	fi
	ac_testn compiler_still_fails '' 'if the compiler still does not fail correctly' <<-EOF
		int main(void) { return (thiswillneverbedefinedIhope()); }
	EOF
	test $HAVE_COMPILER_STILL_FAILS = 1 && exit 1
fi

if test $ct = sunpro; then
	test x"$save_NOWARN" = x"" && save_NOWARN='-errwarn=%none'
	ac_flags 0 errwarnnone "$save_NOWARN"
	test 1 = $HAVE_CAN_ERRWARNNONE || save_NOWARN=
	ac_flags 0 errwarnall "-errwarn=%all"
	test 1 = $HAVE_CAN_ERRWARNALL && DOWARN="-errwarn=%all"
elif test $ct = hpcc; then
	save_NOWARN=
	DOWARN=+We
elif test $ct = msc; then
	save_NOWARN="${ccpc}/w"
	DOWARN="${ccpc}/WX"
elif test $ct = dmc; then
	save_NOWARN="${ccpc}-w"
	DOWARN="${ccpc}-wx"
elif test $ct = bcc; then
	save_NOWARN="${ccpc}-w"
	DOWARN="${ccpc}-w!"
elif test $ct = xlc; then
	save_NOWARN=-qflag=i:e
	DOWARN=-qflag=i:i
elif test $ct = tendra; then
	save_NOWARN=-w
else
	test x"$save_NOWARN" = x"" && save_NOWARN=-Wno-error
	ac_flags 0 wnoerror "$save_NOWARN"
	test 1 = $HAVE_CAN_WNOERROR || save_NOWARN=
	ac_flags 0 werror -Werror
	test 1 = $HAVE_CAN_WERROR && DOWARN=-Werror
fi

test $ct = icc && DOWARN="$DOWARN -wd1419"
NOWARN=$save_NOWARN

#
# Compiler: extra flags (-O2 -f* -W* etc.)
#
i=`echo :"$orig_CFLAGS" | sed 's/^://' | tr -c -d $alll$allu$alln`
# optimisation: only if orig_CFLAGS is empty
test x"$i" = x"" && if test $ct = sunpro; then
	cat >x <<-'EOF'
		int main(void) { return (0); }
		#define __IDSTRING_CONCAT(l,p)	__LINTED__ ## l ## _ ## p
		#define __IDSTRING_EXPAND(l,p)	__IDSTRING_CONCAT(l,p)
		#define pad			void __IDSTRING_EXPAND(__LINE__,x)(void) { }
	EOF
	yes pad | head -n 256 >>x
	ac_flags - 1 otwo -xO2 <x
	rm -f x
elif test $ct = hpcc; then
	ac_flags 1 otwo +O2
elif test $ct = xlc; then
	ac_flags 1 othree "-O3 -qstrict"
	test 1 = $HAVE_CAN_OTHREE || ac_flags 1 otwo -O2
elif test $ct = tcc || $ct = tendra; then
	: no special optimisation
else
	ac_flags 1 otwo -O2
	test 1 = $HAVE_CAN_OTWO || ac_flags 1 optimise -O
fi
# other flags: just add them if they are supported
i=0
if test $ct = gcc; then
	ac_flags 1 fnostrictaliasing -fno-strict-aliasing
	ac_flags 1 fstackprotectorall -fstack-protector-all
	ac_flags 1 fwrapv -fwrapv
	i=1
elif test $ct = icc; then
	ac_flags 1 fnobuiltinsetmode -fno-builtin-setmode
	ac_flags 1 fnostrictaliasing -fno-strict-aliasing
	ac_flags 1 fstacksecuritycheck -fstack-security-check
	i=1
elif test $ct = sunpro; then
	ac_flags 1 v -v
	ac_flags 1 xc99 -xc99 'for support of ISO C99'
elif test $ct = hpcc; then
	ac_flags 1 agcc -Agcc 'for support of GCC extensions'
	ac_flags 1 ac99 -AC99 'for support of ISO C99'
elif test $ct = dmc; then
	ac_flags 1 decl "${ccpc}-r" 'for strict prototype checks'
	ac_flags 1 schk "${ccpc}-s" 'for stack overflow checking'
elif test $ct = bcc; then
	ac_flags 1 strpool "${ccpc}-d" 'if we can enable string pooling'
elif test $ct = msc; then
	ac_flags 1 strpool "${ccpc}/GF" 'if we can enable string pooling'
	cat >x <<-'EOF'
		int main(void) { char test[64] = ""; return (*test); }
	EOF
	ac_flags - 1 stackon "${ccpc}/GZ" 'if we can enable stack checks' <x
	ac_flags - 1 stckall "${ccpc}/Ge" 'stack checks for all functions' <x
	ac_flags - 1 secuchk "${ccpc}/GS" 'for compiler security checks' <x
	rm -f x
	ac_flags 1 wall "${ccpc}/Wall" 'to enable all warnings'
	ac_flags 1 wp64 "${ccpc}/Wp64" 'to enable 64-bit warnings'
elif test $ct = xlc; then
	ac_flags 1 x99 -qlanglvl=extc99
	test 1 = $HAVE_CAN_X99 || ac_flags 1 c99 -qlanglvl=stdc99
	ac_flags 1 rodata "-qro -qroconst -qroptr"
	ac_flags 1 rtcheck -qcheck=all
	ac_flags 1 rtchkc -qextchk
	ac_flags 1 wformat "-qformat=all -qformat=nozln"
	#ac_flags 1 wp64 -qwarn64	# too verbose for now
elif test $ct = tendra; then
	ac_flags 0 ysystem -Ysystem
	test $HAVE_CAN_YSYSTEM = 1 && CPPFLAGS="-Ysystem $CPPFLAGS"
	ac_flags 1 extansi -Xa
elif test $ct = tcc; then
	ac_flags 1 boundschk -b
fi
# flags common to a subset of compilers
if test 1 = $i; then
	ac_flags 1 stdg99 -std=gnu99 'for support of ISO C99 + GCC extensions'
	test 1 = $HAVE_CAN_STDG99 || \
	    ac_flags 1 stdc99 -std=c99 'for support of ISO C99'
	ac_flags 1 wall -Wall
fi
ac_test expstmt '' "if the compiler supports statements as expressions" <<-'EOF'
	#define ksh_isspace(c)	({					\
		unsigned ksh_isspace_c = (c);				\
		(ksh_isspace_c >= 0x09 && ksh_isspace_c <= 0x0D) ||	\
		    (ksh_isspace_c == 0x20);				\
	})
	int main(int ac, char *av[]) { return (ksh_isspace(ac + **av)); }
EOF

# The following tests are run with -Werror if possible
NOWARN=$DOWARN

#
# Compiler: check for stuff that only generates warnings
#
ac_test attribute '' 'if we have __attribute__((...)) at all' <<-'EOF'
	#include <stdlib.h>
	#undef __attribute__
	void fnord(void) __attribute__((noreturn));
	int main(void) { fnord(); }
	void fnord(void) { exit(0); }
EOF

ac_test attribute_bounded attribute 0 'for __attribute__((bounded))' <<-'EOF'
	#include <string.h>
	#undef __attribute__
	int xcopy(const void *, void *, size_t)
	    __attribute__((bounded (buffer, 1, 3)))
	    __attribute__((bounded (buffer, 2, 3)));
	int main(int ac, char *av[]) { return (xcopy(av[0], av[--ac], 1)); }
	int xcopy(const void *s, void *d, size_t n) {
		memmove(d, s, n); return (n);
	}
EOF

ac_test attribute_used attribute 0 'for __attribute__((used))' <<-'EOF'
	static const char fnord[] __attribute__((used)) = "42";
	int main(void) { return (0); }
EOF

# End of tests run with -Werror
NOWARN=$save_NOWARN

#
# mksh: flavours (full/small mksh, omit certain stuff)
#
ac_testn mksh_full '' "if we're building a full-featured mksh" <<-'EOF'
	#ifdef MKSH_SMALL
	#error Nope, MKSH_SMALL is defined.
	#endif
	int main(void) { return (0); }
EOF

ac_testn mksh_defutf8 '' "if we assume UTF-8 is enabled" <<-'EOF'
	#ifndef MKSH_ASSUME_UTF8
	#error Nope, we shall check with setlocale() and nl_langinfo(CODESET)
	#endif
	int main(void) { return (0); }
EOF

if test 0 = $HAVE_MKSH_FULL; then
	if test $ct = xlc; then
		ac_flags 1 fnoinline -qnoinline
	else
		ac_flags 1 fnoinline -fno-inline
	fi

	: ${HAVE_SETLOCALE_CTYPE=0}
	check_categories=$check_categories,smksh
	test 0 = $HAVE_MKSH_DEFUTF8 || check_categories=$check_categories,dutf
fi

#
# Environment: headers
#
ac_header sys/param.h
ac_header sys/mkdev.h
ac_header sys/mman.h sys/types.h
ac_header sys/sysmacros.h
ac_header libgen.h
ac_header libutil.h
ac_header paths.h
ac_header stdbool.h
ac_header stdint.h stdarg.h
ac_header grp.h sys/types.h
ac_header ulimit.h
ac_header values.h

#
# Environment: definitions
#
cat >lft.c <<-'EOF'
	#include <sys/types.h>
	/* check that off_t can represent 2^63-1 correctly, thx FSF */
	#define LARGE_OFF_T (((off_t) 1 << 62) - 1 + ((off_t) 1 << 62))
	int off_t_is_large[(LARGE_OFF_T % 2147483629 == 721 &&
	    LARGE_OFF_T % 2147483647 == 1) ? 1 : -1];
	int main(void) { return (0); }
EOF
ac_testn can_lfs '' "if we support large files" <lft.c
save_CPPFLAGS=$CPPFLAGS
CPPFLAGS="$CPPFLAGS -D_FILE_OFFSET_BITS=64"
ac_testn can_lfs_sus '!' can_lfs 0 "... with -D_FILE_OFFSET_BITS=64" <lft.c
if test 0 = $HAVE_CAN_LFS_SUS; then
	CPPFLAGS="$save_CPPFLAGS -D_LARGE_FILES=1"
	ac_testn can_lfs_aix '!' can_lfs 0 "... with -D_LARGE_FILES=1" <lft.c
	test 1 = $HAVE_CAN_LFS_AIX || CPPFLAGS=$save_CPPFLAGS
fi
rm -f lft.c lft.o	# end of large file support test

#
# Environment: types
#
ac_test rlim_t <<-'EOF'
	#include <sys/types.h>
	#include <sys/time.h>
	#include <sys/resource.h>
	#include <unistd.h>
	int main(void) { return ((int)(rlim_t)0); }
EOF

# only testn: added later below
ac_testn sig_t <<-'EOF'
	#include <sys/types.h>
	#include <signal.h>
	int main(void) { return ((int)(sig_t)0); }
EOF

ac_testn sighandler_t '!' sig_t 0 <<-'EOF'
	#include <sys/types.h>
	#include <signal.h>
	int main(void) { return ((int)(sighandler_t)0); }
EOF
if test 1 = $HAVE_SIGHANDLER_T; then
	CPPFLAGS="$CPPFLAGS -Dsig_t=sighandler_t"
	HAVE_SIG_T=1
fi

ac_testn __sighandler_t '!' sig_t 0 <<-'EOF'
	#include <sys/types.h>
	#include <signal.h>
	int main(void) { return ((int)(__sighandler_t)0); }
EOF
if test 1 = $HAVE___SIGHANDLER_T; then
	CPPFLAGS="$CPPFLAGS -Dsig_t=__sighandler_t"
	HAVE_SIG_T=1
fi

ac_cppflags SIG_T

#
# Environment: signals
#
test x"NetBSD" = x"$TARGET_OS" && $e Ignore the compatibility warning.

for what in name list; do
	uwhat=`upper $what`
	ac_testn sys_sig$what '' "the sys_sig${what}[] array" <<-EOF
		extern const char *const sys_sig${what}[];
		int main(void) { return (sys_sig${what}[0][0]); }
	EOF
	ac_testn _sys_sig$what '!' sys_sig$what 0 "the _sys_sig${what}[] array" <<-EOF
		extern const char *const _sys_sig${what}[];
		int main(void) { return (_sys_sig${what}[0][0]); }
	EOF
	if eval "test 1 = \$HAVE__SYS_SIG$uwhat"; then
		CPPFLAGS="$CPPFLAGS -Dsys_sig$what=_sys_sig$what"
		eval "HAVE_SYS_SIG$uwhat=1"
	fi
	ac_cppflags SYS_SIG$uwhat
done

ac_test strsignal '!' sys_siglist 0 <<-'EOF'
	#include <string.h>
	#include <signal.h>
	int main(void) { return (strsignal(1)[0]); }
EOF

#
# Environment: library functions
#
ac_testn arc4random <<-'EOF'
	#include <sys/types.h>
	#if HAVE_STDINT_H
	#include <stdint.h>
	#endif
	extern u_int32_t arc4random(void);
	int main(void) { return (arc4random()); }
EOF

if test $HAVE_ARC4RANDOM = 0 && test -f "$srcdir/arc4random.c"; then
	ac_header sys/sysctl.h
	addsrcs HAVE_ARC4RANDOM arc4random.c
	HAVE_ARC4RANDOM=1
	HAVE_ARC4RANDOM_DECL=0
	HAVE_ARC4RANDOM_PUSH=0
fi
ac_cppflags ARC4RANDOM

ac_test arc4random_pushb arc4random 0 <<-'EOF'
	#include <sys/types.h>
	#if HAVE_STDINT_H
	#include <stdint.h>
	#endif
	extern uint32_t arc4random_pushb(void *, size_t);
	int main(int ac, char *av[]) { return (arc4random_pushb(*av, ac)); }
EOF

ac_test flock_ex '' 'flock and mmap' <<-'EOF'
	#include <sys/types.h>
	#include <sys/file.h>
	#include <sys/mman.h>
	#include <fcntl.h>
	#include <stdlib.h>
	int main(void) { return (mmap(NULL, flock(0, LOCK_EX), PROT_READ,
	    MAP_FILE | MAP_PRIVATE, 0, 0) == NULL ? 1 : 0); }
EOF

ac_test setlocale_ctype '!' mksh_defutf8 0 'setlocale(LC_CTYPE, "")' <<-'EOF'
	#include <locale.h>
	#include <stddef.h>
	int main(void) { return ((ptrdiff_t)(void *)setlocale(LC_CTYPE, "")); }
EOF

ac_test langinfo_codeset setlocale_ctype 0 'nl_langinfo(CODESET)' <<-'EOF'
	#include <langinfo.h>
	#include <stddef.h>
	int main(void) { return ((ptrdiff_t)(void *)nl_langinfo(CODESET)); }
EOF

ac_test mknod '' 'if we use mknod(), makedev() and friends' <<-'EOF'
	#define MKSH_INCLUDES_ONLY
	#include "sh.h"
	#if defined(MKSH_SMALL) && !defined(MKSH_NEED_MKNOD)
	#error We do not want to include the mknod builtin.
	#endif
	int main(int ac, char *av[]) {
		dev_t dv;
		dv = makedev(ac, 1);
		return (mknod(av[0], 0, dv) ? (int)major(dv) : (int)minor(dv));
	}
EOF

ac_test revoke mksh_full 0 <<-'EOF'
	#if HAVE_LIBUTIL_H
	#include <libutil.h>
	#endif
	#include <unistd.h>
	int main(int ac, char *av[]) { return (ac + revoke(av[0])); }
EOF

ac_test setmode mknod 1 <<-'EOF'
	#if defined(__MSVCRT__) || defined(__CYGWIN__)
	#error Win32 setmode() is different from what we need
	#endif
	#include <unistd.h>
	int main(int ac, char *av[]) { return (getmode(setmode(av[0]), ac)); }
EOF

ac_test setresugid <<-'EOF'
	#include <sys/types.h>
	#include <unistd.h>
	int main(void) { setresuid(0,0,0); return (setresgid(0,0,0)); }
EOF

ac_test setgroups setresugid 0 <<-'EOF'
	#include <sys/types.h>
	#if HAVE_GRP_H
	#include <grp.h>
	#endif
	#include <unistd.h>
	int main(void) { gid_t gid = 0; return (setgroups(0, &gid)); }
EOF

ac_test strcasestr setlocale_ctype 1 <<-'EOF'
	#include <stddef.h>
	#include <string.h>
	int main(int ac, char *av[]) {
		return ((ptrdiff_t)(void *)strcasestr(*av, av[ac]));
	}
EOF

ac_test strlcpy <<-'EOF'
	#include <string.h>
	int main(int ac, char *av[]) { return (strlcpy(*av, av[1], ac)); }
EOF

#
# check headers for declarations
#
ac_test '!' arc4random_decl arc4random 1 'if arc4random() does not need to be declared' <<-'EOF'
	#define MKSH_INCLUDES_ONLY
	#include "sh.h"
	long arc4random(void);		/* this clashes if defined before */
	int main(void) { return (arc4random()); }
EOF
ac_test '!' arc4random_pushb_decl arc4random_pushb 1 'if arc4random_pushb() does not need to be declared' <<-'EOF'
	#define MKSH_INCLUDES_ONLY
	#include "sh.h"
	int arc4random_pushb(char, int); /* this clashes if defined before */
	int main(int ac, char *av[]) { return (arc4random_pushb(**av, ac)); }
EOF
ac_test sys_siglist_decl sys_siglist 1 'if sys_siglist[] does not need to be declared' <<-'EOF'
	#define MKSH_INCLUDES_ONLY
	#include "sh.h"
	int main(void) { return (sys_siglist[0][0]); }
EOF

#
# other checks
#
fd='if to use persistent history'
ac_cache PERSISTENT_HISTORY || test 11 != $HAVE_FLOCK_EX$HAVE_MKSH_FULL || fv=1
test 1 = $fv || check_categories=$check_categories,no-histfile
ac_testdone
ac_cppflags

#
# Compiler: Praeprocessor (only if needed)
#
test 0 = $HAVE_SYS_SIGNAME && if ac_testinit cpp_dd '' \
    'checking if the C Preprocessor supports -dD'; then
	echo '#define foo bar' >scn.c
	eval 'v "$CPP -dD scn.c >x" 2>&'$h | sed 's/^/] /'
	grep '#define foo bar' x >/dev/null 2>&1 && fv=1
	rm -f scn.c x
	ac_testdone
fi

#
# End of mirtoconf checks
#
$e ... done.

# Some operating systems have ancient versions of ed(1) writing
# the character count to standard output; cope for that
echo wq >x
ed x <x 2>/dev/null | grep 3 >/dev/null 2>&1 && \
    check_categories=$check_categories,oldish-ed
rm -f x

if test 0 = $HAVE_SYS_SIGNAME; then
	if test 1 = $HAVE_CPP_DD; then
		$e Generating list of signal names...
	else
		$e No list of signal names available via cpp. Falling back...
	fi
	sigseen=:
	cat >scn.c <<-'EOF'
		#include <signal.h>
		#ifndef NSIG
		#define NSIG _NSIG
		#endif
		mksh_cfg: NSIG
	EOF
	NSIG=`vq "$CPP $CPPFLAGS scn.c" | grep mksh_cfg: | \
	    sed 's/^mksh_cfg:[	 ]*\([0-9x ()+-]*\).*$/\1/'`
	case $NSIG in
	*[\ \(\)+-]*) NSIG=`awk "BEGIN { print $NSIG }"` ;;
	esac
	NSIG=`printf %d "$NSIG" 2>/dev/null`
	test $h = 1 && printf "NSIG=$NSIG ... "
	signames="ABRT ALRM BUS CHLD CLD CONT EMT FPE HUP ILL INFO INT IO IOT"
	signames="$signames KILL PIPE PROF PWR QUIT SAK SEGV STOP SYS TERM"
	signames="$signames TRAP TSTP TTIN TTOU URG USR1 USR2 WINCH XCPU XFSZ"
	test 1 = $HAVE_CPP_DD && test $NSIG -gt 1 && signames="$signames "`vq \
	    "$CPP $CPPFLAGS -dD scn.c" | grep '[	 ]SIG[A-Z0-9]*[	 ]' | \
	    sed 's/^\(.*[	 ]SIG\)\([A-Z0-9]*\)\([	 ].*\)$/\2/' | sort`
	test $NSIG -gt 1 || signames=
	for name in $signames; do
		echo '#include <signal.h>' >scn.c
		echo mksh_cfg: SIG$name >>scn.c
		vq "$CPP $CPPFLAGS scn.c" | grep mksh_cfg: | \
		    sed 's/^mksh_cfg:[	 ]*\([0-9x]*\).*$/\1:'$name/
	done | grep -v '^:' | while IFS=: read nr name; do
		nr=`printf %d "$nr" 2>/dev/null`
		test $nr -gt 0 && test $nr -le $NSIG || continue
		case $sigseen in
		*:$nr:*) ;;
		*)	echo "		{ $nr, \"$name\" },"
			sigseen=$sigseen$nr:
			test $h = 1 && printf "$name=$nr " >&2
			;;
		esac
	done 2>&1 >signames.inc
	rm -f scn.c
	$e done.
fi

addsrcs HAVE_SETMODE setmode.c
addsrcs HAVE_STRLCPY strlcpy.c
CPPFLAGS="$CPPFLAGS -DHAVE_CONFIG_H -DCONFIG_H_FILENAME=\\\"sh.h\\\""

objs=
case $curdir in
*\ *)	echo "#!./mksh" >test.sh ;;
*)	echo "#!$curdir/mksh" >test.sh ;;
esac
echo "export PATH='$PATH'" >>test.sh
echo "exec perl '$srcdir/check.pl' -s '$srcdir/check.t'" \
    "-p '$curdir/mksh' -C $check_categories \$*$tsts" >>test.sh
chmod 755 test.sh
echo set -x >Rebuild.sh
for file in $SRCS; do
	objs="$objs `echo x"$file" | sed 's/^x\(.*\)\.c$/\1.o/'`"
	test -f $file || file=$srcdir/$file
	echo "$CC $CFLAGS $CPPFLAGS -c $file || exit 1" >>Rebuild.sh
done
echo "$CC $CFLAGS $LDFLAGS -o mksh $objs $LIBS" >>Rebuild.sh
test $ct = msc || echo 'test $? = 0 || exit 1' >>Rebuild.sh
echo 'result=mksh; test -f mksh.exe && result=mksh.exe' >>Rebuild.sh
echo 'test -f $result || exit 1; size $result' >>Rebuild.sh
for file in $SRCS; do
	test -f $file || file=$srcdir/$file
	v "$CC $CFLAGS $CPPFLAGS -c $file" || exit 1
done
v "$CC $CFLAGS $LDFLAGS -o mksh $objs $LIBS"
rv=$?; test $ct = msc -o $rv = 0 || exit 1
result=mksh
test -f mksh.exe && result=mksh.exe
test -f $result || exit 1
test $r = 1 || v "$NROFF -mdoc <'$srcdir/mksh.1' >mksh.cat1" || \
    rm -f mksh.cat1
test $eq = 0 && test $h = 1 && v size $result
i=install
test -f /usr/ucb/$i && i=/usr/ucb/$i
test $eq = 1 && e=:
$e
$e Installing the shell:
$e "# $i -c -s -o root -g bin -m 555 mksh /bin/mksh"
$e "# grep -x /bin/mksh /etc/shells >/dev/null || echo /bin/mksh >>/etc/shells"
$e "# $i -c -o root -g bin -m 444 dot.mkshrc /usr/share/doc/mksh/examples/"
$e
$e Installing the manual:
if test -f mksh.cat1; then
	$e "# $i -c -o root -g bin -m 444 mksh.cat1" \
	    "/usr/share/man/cat1/mksh.0"
	$e or
fi
$e "# $i -c -o root -g bin -m 444 mksh.1 /usr/share/man/man1/mksh.1"
$e
$e Run the regression test suite: ./test.sh
$e Please also read the sample file dot.mkshrc and the fine manual.
