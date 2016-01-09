#!/bin/bash
#ffmpeg full none-free install
# Add multimedia source
echo "deb http://www.deb-multimedia.org jessie main non-free" >> /etc/apt/sources.list
echo "deb-src http://www.deb-multimedia.org jessie main non-free" >> /etc/apt/sources.list
apt-get update
apt-get install deb-multimedia-keyring # if this aborts, try again
apt-get update
# Go to local source directory
cd /usr/local/src
apt-get install aptitude
# Install all dependencies we'll need
 aptitude install \
  -y                  \
  libfaad-dev         \
  faad                \
  faac                \
  libfaac0            \
  libfaac-dev         \
  libmp3lame-dev      \
  x264                \
  libx264-dev         \
  libxvidcore-dev     \
  build-essential     \
  libtwolame-dev twolame libtwolame0 \
  ste-plugins swh-plugins tap-plugins vco-plugins wah-plugins zam-plugins \
  ladspa-sdk invada-studio-plugins-ladspa caps libwebp-dev \
  checkinstall
# Install all build dependencies for ffmpeg
 apt-get build-dep ffmpeg
# Get the actual ffmpeg source code

if [ -d ffmpeg ] 
 then
   cd ffmpeg
   git pull
else 
   git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg
  cd ffmpeg
fi
# Go into the ffmpeg source directory
set -x
# Configure it
./configure \
--enable-gpl \
--enable-nonfree \
--enable-libfaac \
--enable-libgsm \
--enable-libmp3lame \
--enable-libtheora \
--enable-libvorbis \
--enable-libx264 \
--enable-libxvid \
--enable-zlib \
--enable-postproc \
--enable-swscale \
--enable-pthreads \
--enable-x11grab \
--enable-libdc1394 \
--enable-version3 \
--enable-libopencore-amrnb \
--enable-libopencore-amrwb \
--enable-libaacplus \
--enable-libass \
--enable-libfdk-aac \
--enable-libopenjpeg \
--enable-ladspa \
--enable-libwebp \
--enable-iconv \
--enable-hardcoded-tables \
--enable-postproc \
--disable-outdev=oss \
--enable-ffplay \
--enable-libtwolame \
--enable-libmp3lame \
--disable-runtime-cpudetect \
--cpu=host 
# a fix
mkdir -p /usr/local/share/ffmpeg 
mkdir -p /usr/local/share/doc 
mkdir -p /usr/local/share/man
mkdir -p /usr/local/include
make -j4
# Generate the debian package (*.deb)
checkinstall -D --install=no --pkgname=ffmpeg-git --pkgversion=git_2.9999  --autodoinst=yes -y
# install the package :)
dpkg -i ffmpeg-git_*amd64.deb
