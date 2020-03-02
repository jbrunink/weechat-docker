FROM alpine:latest

ENV WEECHAT_VERSION 2.7.1
ENV WEECHAT_HOME /weechat
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS 2
ENV S6_VERSION v1.22.1.0

RUN GPG_KEYS=A9AB5AB778FA5C3522FD0378F82F4B16DEC408F8 \
	&& set -e \
	&& addgroup -S weechat \
	&& adduser -D -S -h /weechat -s /sbin/nologin -G weechat weechat \
	&& apk add --no-cache --virtual .run-deps \
		curl \
		gnupg \
		python2 \
		libgcrypt \
		gnutls \
		libcurl \
		ncurses-libs \
		python2 \
		tzdata \
		tcl \
		aspell \
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		cmake \
		make \
		libc-dev \
		pkgconfig \
		libgcrypt-dev \
		ncurses-dev \
		curl-dev \
		zlib-dev \
		gnutls-dev \
		python2-dev \
		gettext-dev	\
		aspell-dev \
		tcl-dev \
		asciidoctor \
	&& curl -fSL https://weechat.org/files/src/weechat-${WEECHAT_VERSION}.tar.gz -o weechat.tar.gz \
	&& curl -fSL https://weechat.org/files/src/weechat-${WEECHAT_VERSION}.tar.gz.asc -o weechat.tar.gz.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& found=''; \
	for server in \
		pgp.key-server.io \
	; do \
		echo "Fetching GPG key $GPG_KEYS from $server"; \
		gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
	gpg --batch --verify weechat.tar.gz.asc weechat.tar.gz \
	&& rm -rf "$GNUPGHOME" weechat.tar.gz.asc \
	&& mkdir -p /usr/src \
	&& tar -zxC /usr/src -f weechat.tar.gz \
	&& rm weechat.tar.gz \
	&& cd /usr/src/weechat-${WEECHAT_VERSION} \
	&& mkdir build \
	&& cd build \
	&& cmake -Wno-dev .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DENABLE_PYTHON2=ON \
		-DENABLE_PERL=OFF \
		-DENABLE_RUBY=OFF \
		-DENABLE_LUA=OFF \
		-DENABLE_GUILE=OFF \
		-DENABLE_JAVASCRIPT=OFF \
		-DENABLE_PHP=OFF \
		-DENABLE_SPELL=ON \
		-DENABLE_TCL=ON \
		-DENABLE_MAN=ON \
		-DENABLE_DOC=ON \
	&& make \
	&& make install \
	&& rm -rf /usr/src/weechat-${WEECHAT_VERSION} \
	&& apk del .build-deps

RUN GPG_KEYS=DB301BA3F6F807E0D0E6CCB86101B2783B2FD161 \
	&& curl -fSL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-amd64.tar.gz -o s6-overlay-amd64.tar.gz \
	&& curl -fSL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-amd64.tar.gz.sig -o s6-overlay-amd64.tar.gz.sig \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& found=''; \
	for server in \
		pgp.key-server.io \
	; do \
		echo "Fetching GPG key $GPG_KEYS from $server"; \
		gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
	gpg --batch --verify s6-overlay-amd64.tar.gz.sig s6-overlay-amd64.tar.gz \
	&& tar xzf s6-overlay-amd64.tar.gz -C / \
	&& rm -rf "$GNUPGHOME" s6-overlay-amd64.tar.gz s6-overlay-amd64.tar.gz.sig

RUN cp /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime \
	&& echo "Europe/Amsterdam" > /etc/timezone

COPY ["./fix-attrs.d", "/etc/fix-attrs.d"]

ENTRYPOINT ["/init"]
CMD ["s6-setuidgid", "weechat", "/usr/bin/weechat"]