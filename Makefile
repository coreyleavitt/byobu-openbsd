COMMENT =	text-based window manager and terminal multiplexer

V =		6.14
DISTNAME =	byobu-${V}
CATEGORIES =	sysutils

HOMEPAGE =	https://www.byobu.org/
MAINTAINER =	Corey Leavitt <corey@coreyleavitt.com>

# GPLv3
PERMIT_PACKAGE =	Yes

MASTER_SITES =	https://github.com/dustinkirkland/byobu/archive/refs/tags/
DISTFILES =	${V}.tar.gz

WRKDIST =	${WRKDIR}/byobu-${V}

BUILD_DEPENDS =	devel/autoconf/${AUTOCONF_VERSION} \
		devel/automake/${AUTOMAKE_VERSION}

RUN_DEPENDS =	shells/bash \
		misc/tmux

AUTOCONF_VERSION =	2.71
AUTOMAKE_VERSION =	1.16

CONFIGURE_STYLE =	gnu
CONFIGURE_ARGS =	--prefix=${PREFIX}

USE_GMAKE =		No

pre-configure:
	cd ${WRKSRC} && AUTOCONF_VERSION=${AUTOCONF_VERSION} \
		AUTOMAKE_VERSION=${AUTOMAKE_VERSION} autoreconf -fi

.include <bsd.port.mk>
