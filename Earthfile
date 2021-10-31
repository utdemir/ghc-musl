all:
    FROM alpine:3.14.0

    ARG VERSION=22

    ENV BASE_TAG=utdemir/ghc-musl:v$VERSION

    ENV TAG1=$BASE_TAG-ghc921
    BUILD --build-arg TAG=$TAG1 --build-arg ALPINE=3.14.2 --build-arg GHC=9.2.1  --build-arg CABAL=3.6.0.0 +tested-result

    ENV TAG2=$BASE_TAG-ghc901
    BUILD --build-arg TAG=$TAG2 --build-arg ALPINE=3.14.2 --build-arg GHC=9.0.1  --build-arg CABAL=3.4.0.0 +tested-result

    ENV TAG3=$BASE_TAG-ghc8107
    BUILD --build-arg TAG=$TAG3 --build-arg ALPINE=3.14.2 --build-arg GHC=8.10.7 --build-arg CABAL=3.2.0.0 +tested-result

    RUN apk add bash gettext
    COPY ./update-readme.sh .
    RUN ./update-readme.sh "$TAG1" "$TAG2" "$TAG3"
    SAVE ARTIFACT README.md

base-system:
    ARG ALPINE
    FROM alpine:$ALPINE

    RUN echo 2021-10-30-3

    RUN apk update \
          && apk add \
               gcc g++ bash git make xz tar binutils-gold \
               perl curl file automake autoconf dpkg \
               fakeroot findutils shadow

    RUN apk add \
          gmp-dev ncurses-dev \
          libffi libffi-dev \
          openssl-dev openssl-libs-static \
          xz xz-dev ncurses-static \
          pcre pcre-dev pcre2 pcre2-dev \
          bzip2 bzip2-dev bzip2-static \
          curl libcurl curl-static \
          zlib zlib-dev zlib-static \
          sdl sdl-dev sdl-static \
          sdl_mixer sdl_mixer-dev \
          sdl_image sdl_image-dev \
          sdl2 sdl2-dev \
          sdl2_mixer sdl2_mixer-dev \
          sdl2_image sdl2_image-dev \
          sdl2_ttf sdl2_ttf-dev \
          freetype freetype-dev freetype-static \
          libpng libpng-static \
          brotli brotli-static

    RUN ln -s /usr/lib/libncursesw.so.6 /usr/lib/libtinfo.so.6

ghcup:
    FROM +base-system
    ENV GHCUP_INSTALL_BASE_PREFIX=/usr/local
    RUN curl --fail -o /bin/ghcup \
          'https://downloads.haskell.org/ghcup/x86_64-linux-ghcup' \
          && chmod +x /bin/ghcup

    RUN ghcup upgrade --target /bin/ghcup

ghc-deps:
    FROM +ghcup

    ARG GHC
    RUN ghcup install ghc "$GHC" \
          && ghcup set ghc "$GHC"

    ARG CABAL
    RUN ghcup install cabal "$CABAL" \
          && ghcup set cabal "$CABAL"

result:
    FROM +ghc-deps
    ENV PATH="/usr/local/.ghcup/bin:$PATH"
    RUN cabal update

tested-result:
    FROM +result
    BUILD +test

    ARG TAG
    SAVE IMAGE --push "$TAG"

test:
    FROM busybox
    BUILD +test-cabal

    # stack tests are not enabled on the CI because they require the
    # --privileged flag which is not available on GitHub actions.
    BUILD +test-stack

test-cabal:
    FROM +result
    COPY example /example
    WORKDIR /example/
    RUN cabal update && cabal new-build example --enable-executable-static

    # below tests would be nice to have, but 'cabal list-bin' is only present
    # on cabal-install >=3.2

    # RUN file $(cabal list-bin example) | grep 'statically linked'
    # RUN $(cabal list-bin example) | grep 'Hello World!'

test-stack-base:
    FROM earthly/dind:alpine
    RUN apk add curl
    RUN curl -sSL https://get.haskellstack.org/ | sh
    COPY example /example
    WORKDIR /example/

test-stack:
    FROM +test-stack-base

    WITH DOCKER --load result=+result
        RUN stack build \
            --ghc-options '-static -optl-static -optl-pthread -fPIC' \
            --docker --docker-image result
    END
