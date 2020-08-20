ARG BASE_IMAGE
FROM $BASE_IMAGE

RUN apk update \
      && apk add \
           gcc g++ bash git make xz tar binutils-gold \
           perl curl file automake autoconf dpkg \
           fakeroot findutils

RUN apk add \
      gmp-dev ncurses-dev \
      libffi libffi-dev \
      openssl-dev openssl-libs-static \
      xz xz-dev ncurses-static \
      pcre pcre-dev pcre2 pcre2-dev \
      bzip2 bzip2-dev bzip2-static \
      curl libcurl curl-static \
      zlib zlib-dev zlib-static

RUN curl --fail -o /bin/ghcup \
      'https://downloads.haskell.org/ghcup/x86_64-linux-ghcup' \
      && chmod +x /bin/ghcup

ARG GHC_VERSION
RUN ghcup install ghc "$GHC_VERSION" \
      && ghcup set ghc "$GHC_VERSION"

ARG CABAL_VERSION
RUN ghcup install cabal "$CABAL_VERSION" \
      && ghcup set cabal "$CABAL_VERSION"

ENV PATH="/root/.cabal/bin:/root/.ghcup/bin:$PATH"

RUN cabal new-update
