FROM debian:bullseye-slim as base

WORKDIR /
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && \
    apt-get install --yes --no-install-recommends \
        g++ \
        gcc \
        git \
        curl \
        nasm \
        yasm \
        libgtk-3-dev \
        clang \
        libxcb-randr0-dev \
        libxdo-dev \
        libxfixes-dev \
        libxcb-shape0-dev \
        libxcb-xfixes0-dev \
        libasound2-dev \
        libpam0g-dev \
        libpulse-dev \
        make \
        cmake \
        unzip \
        zip \
        sudo \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        ca-certificates \
        ninja-build && \
        rm -rf /var/lib/apt/lists/*

RUN git clone --branch 2023.04.15 --depth=1 https://github.com/microsoft/vcpkg && \
    /vcpkg/bootstrap-vcpkg.sh -disableMetrics && \
    /vcpkg/vcpkg --disable-metrics install libvpx libyuv opus aom

RUN groupadd -r user && \
    useradd -r -g user user --home /home/user && \
    mkdir -p /home/user/rustdesk && \
    chown -R user: /home/user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/user

WORKDIR /home/user
RUN curl -LO https://raw.githubusercontent.com/c-smile/sciter-sdk/master/bin.lnx/x64/libsciter-gtk.so

USER user
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh && \
    chmod +x rustup.sh && \
    ./rustup.sh -y

USER root
ENV HOME=/home/user
COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

#--------------------------

FROM base AS build-env

## Install dependencies using package manager
#
# Update
RUN apt-get update
#
# Install dependencies used on vcpkg install
RUN apt-get install -y build-essential pkg-config zip unzip wget curl git nasm
#
# Install dependencies used on flutter web build
RUN apt-get install -y cargo cmake python3-clang libgtk-3-dev

RUN apt-get update && \
    apt-get install -y curl git wget unzip libgconf-2-4 gdb libstdc++6 libglu1-mesa fonts-droid-fallback lib32stdc++6 clang cmake ninja-build pkg-config libgtk-3-dev npm python3 protobuf-compiler && \
	ln -s /usr/bin/python3 /usr/bin/python && \
    apt-get clean

# RUN apt-get install -y curl git unzip cargo cmake
# # RUN apt-get install -y curl git unzip cargo cmake libopus-dev libvpx-dev aom-tools
# RUN apt-get install -y build-essential pkg-config zip unzip wget curl git nasm
# RUN apt-get install -y curl git unzip cargo cmake python3 pip python3-clang pkg-config libgtk-3-dev
# RUN apt install -y g++ gcc git curl wget nasm yasm libgtk-3-dev clang libxcb-randr0-dev libxdo-dev libxfixes-dev libxcb-shape0-dev libxcb-xfixes0-dev libasound2-dev libpulse-dev cmake unzip zip sudo libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

## Install vcpkg
# @see https://lindevs.com/install-vcpkg-on-ubuntu
ENV VCPKG_ROOT=/opt/vcpkg
RUN wget -qO vcpkg.tar.gz https://github.com/microsoft/vcpkg/archive/master.tar.gz
RUN mkdir $VCPKG_ROOT
RUN tar xf vcpkg.tar.gz --strip-components=1 -C $VCPKG_ROOT
RUN $VCPKG_ROOT/bootstrap-vcpkg.sh
RUN ln -s $VCPKG_ROOT/vcpkg /usr/local/bin/vcpkg
RUN rm -rf vcpkg.tar.gz

## Install dependencies using vcpkg
RUN export VCPKG_ROOT=$VCPKG_ROOT
RUN vcpkg install libvpx libyuv opus aom

## Install Flutter
ARG FLUTTER_SDK=/usr/local/flutter
#ARG FLUTTER_VERSION=3.16.5
ARG FLUTTER_VERSION=3.22.1
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_SDK
RUN cd $FLUTTER_SDK && git fetch && git checkout $FLUTTER_VERSION
ENV PATH="$FLUTTER_SDK/bin:$FLUTTER_SDK/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter doctor -v
RUN flutter config --enable-web

## Prepare container
#
ARG APP=/app
ARG WEB=/var/www/html/web.rustdesk.com/
RUN mkdir -p $APP
COPY . $APP
WORKDIR $APP

## ===== Web JS
WORKDIR $APP/flutter/web/js

# files are now split into v1 and v2, v2 not public, need to copy to web folder to have correct pathes in scripts
RUN cp -R ../v1/* ../

# Add NodeSource PPA to install a newer version of Node.js
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -

# pin nodejs repo
RUN printf 'Package: nodejs\n Pin: origin deb.nodesource.com\nPin-Priority: 600' > /etc/apt/preferences.d/nodesource

RUN apt-get install -y nodejs

RUN npm install -g npm@9.8.1

# Install Node.js dependencies
RUN npm install -g yarn typescript protoc --force
RUN npm install ts-proto vite@2.8 yarn typescript protoc --force
RUN npm install typescript@latest

RUN yarn build

## ===== Web deps
WORKDIR $APP/flutter/web
RUN wget https://github.com/rustdesk/doc.rustdesk.com/releases/download/console/web_deps.tar.gz
RUN tar xzf web_deps.tar.gz

## ===== Build Web app
WORKDIR $APP/flutter
RUN ./run.sh build web --release --verbose
# RUN ./run.sh build web --web-renderer html --release --verbose
# RUN ./run.sh build web --web-renderer canvaskit --release --verbose

# # Create folder used by script
# RUN mkdir -p $WEB

# # once heare the app will be compiled and ready to deploy
# RUN deploy.sh

# # Set folder as working dir
# WORKDIR $WEB

# # # Start the server
# # ARG PORT=5000
# # EXPOSE $PORT
# # ENTRYPOINT ["echo Server starting on port $PORT ... && python3 -m http.server $PORT"]

# ENTRYPOINT [ "tail", "-f", "/dev/null" ]
ENTRYPOINT [ "ls", "-al", "/app/build/web/" ]

# # --- Step 2: Server Configuration ---

FROM ubuntu:20.04 AS runtime

# Install Python3
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y python3 psmisc && \
    apt-get clean

# Copy necessary files from the build stage
COPY --from=build-env /app/flutter/build/web /app/build/web
COPY server.sh /app/server/

# Expose the port and run the startup script
EXPOSE 5000
WORKDIR /app/server
RUN chmod +x server.sh
ENTRYPOINT ["./server.sh"]
