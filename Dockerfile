###
# Build image
###
FROM nvidia/cuda:9.0-devel-ubuntu16.04 AS build

ENV XMRIG_VERSION v2.4.2

WORKDIR /usr/local/src

RUN set -x \
    && buildDeps=' \
        git \
        libssl-dev \
        build-essential \
        cmake \
        libuv1-dev \
        libmicrohttpd-dev \
    ' \
    && apt-get -qq update \
    && apt-get -qq --no-install-recommends install $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
    \
    && git config --system http.sslverify false \
    && git clone --depth 1 https://github.com/xmrig/xmrig-nvidia.git \
    && cd xmrig-nvidia \
    && git checkout -b ${XMRIG_VERSION} \
    && sed -i 's/constexpr const int kDonateLevel.*/constexpr const int kDonateLevel = 0;/' src/donate.h \
    \
    && cmake -DCUDA_ARCH=61 -DWITH_AEON=OFF . \
    && make -j$(nproc)

###
# Deployed image
###
FROM nvidia/cuda:9.0-devel-ubuntu16.04

WORKDIR /app

RUN apt-get update \
    && apt-get -qq --no-install-recommends install \
        curl \
        libuv1-dev \
        libmicrohttpd-dev \
    && rm -r /var/lib/apt/lists/*
COPY --from=build /usr/local/src/xmrig-nvidia/xmrig-nvidia .

ENTRYPOINT ["/app/xmrig-nvidia"]

