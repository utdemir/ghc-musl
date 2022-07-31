VERSION 0.6

ARG ALPINE_VERSION=3.16.1
FROM alpine:$ALPINE_VERSION

ARG DATE=$(date --utc +%Y%m%d)

ARG IMAGE_NAME=utdemir/ghc-musl

base-system:
  FROM alpine:$ALPINE_VERSION
  RUN apk update \
   && apk upgrade \
   && apk add \
        autoconf automake bash binutils-gold curl dpkg fakeroot file \
        findutils g++ gcc git make perl shadow tar xz \
   && apk add \
        brotli brotli-static \
        bzip2 bzip2-dev bzip2-static \
        curl libcurl curl-static \
        freetype freetype-dev freetype-static \
        gmp-dev \
        libffi libffi-dev \
        libpng libpng-static \
        ncurses-dev ncurses-static \
        openssl-dev openssl-libs-static \
        pcre pcre-dev \
        pcre2 pcre2-dev \
        sdl2 sdl2-dev \
        sdl2_image sdl2_image-dev \
        sdl2_mixer sdl2_mixer-dev \
        sdl2_ttf sdl2_ttf-dev \
        xz xz-dev \
        zlib zlib-dev zlib-static \
   && ln -s /usr/lib/libncursesw.so.6 /usr/lib/libtinfo.so.6

ghcup:
  FROM +base-system
  ENV GHCUP_INSTALL_BASE_PREFIX=/usr/local
  RUN curl --fail --output /bin/ghcup \
        'https://downloads.haskell.org/ghcup/x86_64-linux-ghcup' \
   && chmod 0755 /bin/ghcup \
   && ghcup upgrade --target /bin/ghcup \
   && ghcup install cabal --set \
   && /usr/local/.ghcup/bin/cabal update
  ENV PATH="/usr/local/.ghcup/bin:$PATH"

ghc:
  FROM +ghcup
  ARG --required GHC
  RUN ghcup install ghc "$GHC" --set

test-cabal:
  FROM +ghc
  COPY example /example
  WORKDIR /example/
  RUN cabal new-build example --enable-executable-static
  RUN file $(cabal list-bin example) | grep 'statically linked'
  RUN echo test | $(cabal list-bin example) | grep 'Hello World!'

test-stack:
  FROM earthly/dind:alpine
  RUN apk add curl file \
   && curl -sSL https://get.haskellstack.org/ | sh
  COPY example /example
  WORKDIR /example/
  WITH DOCKER --load ghc-musl=+ghc
    RUN stack build \
          --ghc-options '-static -optl-static -optl-pthread -fPIC' \
          --docker --docker-image ghc-musl
  END
  RUN file $(find /example/.stack-work/install/ -type f -name example) \
    | grep 'statically linked'
  RUN echo test \
    | $(find /example/.stack-work/install/ -type f -name example) \
    | grep 'Hello World!'

image:
  FROM +ghc
  ARG TEST_CABAL=1
  ARG TEST_STACK=1
  ARG --required GHC
  ARG TAG_GHC=0
  IF [ "$TEST_CABAL" = "1" ]
    BUILD +test-cabal
  END
  IF [ "$TEST_STACK" = "1" ]
    BUILD +test-stack
  END
  IF [ "$TAG_GHC" = "1" ]
    SAVE IMAGE --push "${IMAGE_NAME}:ghc${GHC}"
  END
  SAVE IMAGE --push "${IMAGE_NAME}:ghc${GHC}-alpine${ALPINE_VERSION}"
  SAVE IMAGE --push "${IMAGE_NAME}:ghc${GHC}-alpine${ALPINE_VERSION}-${DATE}"

ghc9.2.4:
  BUILD +image --GHC=9.2.4

ghc9.0.2:
  BUILD +image --GHC=9.0.2

ghc8.10.7:
  BUILD +image --GHC=8.10.7

ghc8.8.4:
  BUILD +image --GHC=8.8.4

readme:
  RUN apk add bash gettext
  COPY ./update-readme.sh .
  RUN ./update-readme.sh \
        "${IMAGE_NAME}:ghc9.2.4-alpine${ALPINE_VERSION}-${DATE}" \
        "${IMAGE_NAME}:ghc9.0.2-alpine${ALPINE_VERSION}-${DATE}" \
        "${IMAGE_NAME}:ghc8.10.7-alpine${ALPINE_VERSION}-${DATE}" \
        "${IMAGE_NAME}:ghc8.8.4-alpine${ALPINE_VERSION}-${DATE}"
  SAVE ARTIFACT README.md

all:
  BUILD +ghc9.2.4
  BUILD +ghc9.0.2
  BUILD +ghc8.10.7
  BUILD +ghc8.8.4
  BUILD +readme
