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

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# Keys
RUN apt-get update -o Acquire::AllowInsecureRepositories=true \
    && apt-get install -y --no-install-recommends ubuntu-keyring \
    && apt-get update \
    && apt-get upgrade -y

RUN apt install -y tzdata

RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update \
    && apt-get install -y python3.14-dev

RUN apt-get update && apt-get install -y \
  git g++-14 build-essential autoconf autotools-dev gettext libtool libtool-bin unzip swig \
  python3-usb python3-requests \
  libz-dev libssl-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libsigc++-3.0-dev \
  libfreetype6-dev libfribidi-dev \
  libavahi-client-dev libjpeg-dev libgif-dev libsdl2-dev libxml2-dev libwebp-dev libswscale-dev libavutil-dev \
  libarchive-dev libcurl4-openssl-dev libgpgme11-dev libtirpc-dev \
  x11vnc xvfb xdotool nginx openssh-server curl vsftpd nano locales iputils-ping net-tools gdb valgrind libsqlite3-dev libuchardet-dev


RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV PYTHONUTF8=1


RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 1
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 1

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.14 1
RUN rm /usr/bin/python3 && ln -sf /usr/bin/python3.14 /usr/bin/python3
RUN rm /usr/bin/pygettext3 && ln -sf /usr/bin/pygettext3.14 /usr/bin/pygettext3
RUN rm /usr/bin/pydoc3 && ln -sf /usr/bin/pydoc3.14 /usr/bin/pydoc3

RUN apt-get install -y python3-pip

RUN pip install --upgrade --force-reinstall setuptools

RUN pip3 install Twisted wifi CT3 pillow treq future netifaces cffi puremagic tmdbsimple tvdbsimple tinytag mutagen python-dateutil lxml --break-system-packages

RUN update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-14 1

WORKDIR /work

RUN git clone --depth 1 https://github.com/oe-alliance/libdvbsi.git
RUN cd libdvbsi \
  && ./autogen.sh \
  && ./configure --prefix=/usr \
  && make \
  && make install

RUN git clone --depth 1 https://github.com/oe-alliance/tuxtxt.git
RUN cd tuxtxt/libtuxtxt \
  && autoreconf -i \
  && CPP="gcc -E -P" ./configure --with-boxtype=generic --prefix=/usr \
  && make \
  && make install

RUN cd tuxtxt/tuxtxt \
  && autoreconf -i \
  && CPP="gcc -E -P" ./configure --with-boxtype=generic --prefix=/usr \
  && make \
  && make install

ARG OPKG_VER="0.7.0"
RUN curl -L https://downloads.yoctoproject.org/releases/opkg/opkg-$OPKG_VER.tar.gz -o opkg.tar.gz
RUN tar -xzf opkg.tar.gz
RUN cd "opkg-$OPKG_VER" \
  && autoreconf -i \
  && ./configure --enable-gpg --disable-curl --prefix=/usr --sysconfdir=/etc \
  && make \
  && make install


RUN git clone --depth 1 https://github.com/openatv/enigma2.git
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
RUN git clone --depth 1 https://github.com/openatv/oe-alliance-e2-skindefault.git
RUN cd oe-alliance-e2-skindefault \
 && cp -arv fonts /usr/share/ \
 && cp -arv skin_default /usr/share/enigma2/ \
 && cp skin*.xml /usr/share/enigma2/ \
 && cp prev.png /usr/share/enigma2/

#WeatherInfo
RUN git clone --depth 1 https://github.com/openatv/WeatherInfo.git
RUN cd WeatherInfo && cp Weatherinfo.py /usr/lib/enigma2/python/Tools/

#metrix
RUN git clone --depth 1 https://github.com/openatv/MetrixHD.git -b master
RUN cd MetrixHD && cp -arv usr /

# OPKG
RUN mkdir -p /etc/opkg && mkdir -p /var/lib/opkg/lists && mkdir -p /var/lib/opkg/info \
  && echo "dest root /" > /etc/opkg/opkg.conf \
  && echo "option lists_dir /var/lib/opkg/lists" >> /etc/opkg/opkg.conf \
  && echo "option status_file /var/lib/opkg/status" >> /etc/opkg/opkg.conf \
  && echo "arch all 1" > /etc/opkg/arch.conf \
  && echo "arch any 6" >> /etc/opkg/arch.conf \
  && echo "arch noarch 11" >> /etc/opkg/arch.conf \
  && echo "src/gz openatv-all http://feeds2.mynonpublic.com/7.4/vusolo4k/all" >> /etc/opkg/all-feed.conf \
  && echo "src/gz oe-alliance-settings-feed https://raw.githubusercontent.com/oe-alliance/oe-alliance-settings-feed/master/feed" >> /etc/opkg/oe-alliance-settings-feed.conf

COPY opkg.py /work/opkg.py
RUN python opkg.py

RUN if [ -f /usr/lib32/libc.so.6 ]; then ln -snf /usr/lib32/libc.so.6 /usr/lib/libc.so.6 && chmod 755 /usr/lib32/libc.so.6; fi
RUN if [ -f /usr/lib/aarch64-linux-gnu/libc.so.6 ]; then ln -snf /usr/lib/aarch64-linux-gnu/libc.so.6 /usr/lib/libc.so.6 && chmod 755 /usr/lib/aarch64-linux-gnu/libc.so.6; fi


RUN mkdir -p /media/hdd/movie && mkdir -p /media/hdd/picon && mkdir -p /hdd && mkdir -p /etc/enigma2 && mkdir -p /etc/tuxtxt && mkdir -p /dev/input
COPY enigma.info /usr/lib/enigma.info
COPY process.py /usr/lib/python3.14/process.py
COPY etc/* /etc/enigma2/
WORKDIR /src
CMD ["/bin/bash"]