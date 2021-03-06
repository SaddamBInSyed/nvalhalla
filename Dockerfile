FROM nvcr.io/nvidia/deepstream:5.0-dp-20.04-devel

# set up source dir and copy source
WORKDIR /opt/nvalhalla/source
COPY meson.build COPYING VERSION ./
COPY docs ./docs/
COPY includes ./includes/
COPY models ./models/
COPY nvinfer_configs ./nvinfer_configs/
COPY scripts ./scripts/
COPY test ./test/
COPY src ./src/

# install build dependencies, build, install, and uninstall build deps
# (all in one layer so as not to increase size)
# yes a multi-stage build could also be used, this is the "old" way
# amont other things, we break interactive login capability.

# TODO(mdegans): figure out why libnice plugins like webrtcbin don't work
# I figured it was dependencies, but even with this it fails:
# libnice10 \
# libgstreamer-plugins-good1.0-0 \
# libgstreamer-plugins-bad1.0-0 \
# suspect the webrtcbin plugin is broken
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgee-0.8-2 \
    libgee-0.8-dev \
    libglib2.0-dev \
    libgstreamer1.0-dev \
    libgstrtspserver-1.0-dev \
    ninja-build \
    python3-pip \
    python3-setuptools \
    valac \
    && pip3 install meson \
    && chmod -R o-w /opt/nvidia/deepstream/deepstream/samples /opt/nvidia/deepstream/deepstream/sources \
    && useradd -md /var/nvalhalla -rUs /bin/false nvalhalla \
    && mkdir build \
    && cd build \
    && meson .. \
    && ninja \
    && ninja test \
    && ninja install \
    && ninja clean \
    && pip3 uninstall -y meson \
    && apt-get purge -y --autoremove \
    libgee-0.8-dev \
    libglib2.0-dev \
    libgstreamer1.0-dev \
    libgstrtspserver-1.0-dev \
    ninja-build \
    python3-pip \
    python3-setuptools \
    valac

ARG NVALHALLA_VERSION="UNDEFINED use build.sh to build"

# drop caps and run nvalhalla using the rtsp sink
USER nvalhalla:nvalhalla
ENV G_MESSAGES_DEBUG="all"
EXPOSE 8554/tcp
ENTRYPOINT ["nvalhalla", "--sink", "rtsp"]
