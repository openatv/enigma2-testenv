# Copyright (c) 2026 jbleyel
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    for i in 1 2 3 4 5; do \
      add-apt-repository -y ppa:deadsnakes/ppa && break || sleep 10; \
    done && \
    apt-get remove -y libunwind-14-dev || true && \
    apt-get install -y \
        g++-14 \
        gcc-14 \
        linux-libc-dev \
        git \
        build-essential \
        automake \
        autoconf \
        libtool \
        python3.13 \
        python3.13-dev \
        zlib1g-dev \
        gettext \
        swig \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libfreetype6-dev \
        libfribidi-dev \
        libavahi-client-dev \
        libjpeg-turbo8-dev \
        libgif-dev \
        libpng-dev \
        libwebp-dev \
        libxml2-dev \
        libssl-dev \
        libcrypto++-dev \
        libcurl4-openssl-dev \
        libsqlite3-dev \
        mm-common \
        pkg-config \
        wget \
        curl \
        unzip \
        ca-certificates

# Set gcc-14 and g++-14 as default
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100

# Build and install libdvbsi++
RUN cd /tmp && \
    git clone --depth 1 https://github.com/oe-alliance/libdvbsi.git && \
    cd libdvbsi && \
    autoreconf -i && \
    ./configure && \
    make && \
    make install

# Build and install libsigc++-3
RUN cd /tmp && \
    git clone --depth 1 https://github.com/TwolDE2/libsigc--3.0.git && \
    cd libsigc--3.0 && \
    autoreconf -i && \
    ./configure && \
    make && \
    make install

# Build and install tuxbox
RUN cd /tmp && \
    git clone --depth 1 https://github.com/oe-alliance/tuxtxt.git && \
    cd tuxtxt/libtuxtxt && \
    autoreconf -i && \
    ./configure --with-boxtype=generic DVB_API_VERSION=5 && \
    make && \
    make install && \
    cd ../tuxtxt && \
    autoreconf -i && \
    ./configure --with-boxtype=generic DVB_API_VERSION=5 && \
    make && \
    make install

ARG OPKG_VER="0.7.0"
RUN curl -L https://git.yoctoproject.org/opkg/snapshot/opkg-$OPKG_VER.tar.gz -o opkg.tar.gz
RUN tar -xzf opkg.tar.gz
RUN cd "opkg-$OPKG_VER" \
  && autoreconf -i \
  && ./configure --enable-gpg --disable-curl --prefix=/usr --sysconfdir=/etc \
  && make \
  && make install

RUN git clone --depth 1 https://github.com/openatv/enigma2.git -b master
COPY ax_python_devel.m4 /work/enigma2/m4/ax_python_devel.m4
RUN cd enigma2 \
  && ./autogen.sh \
  && ./configure --with-libsdl --with-gstversion=1.0 --prefix=/usr --sysconfdir=/etc --with-boxtype=dm920 \
  && make -j4 \
  && make install
RUN ldconfig


#branding
RUN git clone --depth 1 https://github.com/oe-mirrors/branding-module.git
COPY ax_python_devel.m4 branding-module/m4/ax_python_devel.m4
RUN cd branding-module \
  && autoreconf -i \
  && ./configure --prefix=/usr --with-imageversion="7.4" \
  && make \
  && make install
    
#default skin
RUN git clone --depth 1 https://github.com/openatv/oe-alliance-e2-skindefault.git -b V2
RUN cd oe-alliance-e2-skindefault \
  && cp -arv fonts /usr/share/ \
  && cp -arv skin_default /usr/share/enigma2/ \
  && cp prev.png /usr/share/enigma2/


#metrix
RUN git clone --depth 1 https://github.com/openatv/MetrixHD.git -b master
RUN cd MetrixHD && cp -arv usr /


WORKDIR /src
CMD ["/bin/bash"]