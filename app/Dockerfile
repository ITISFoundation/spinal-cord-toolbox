FROM ubuntu:20.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    gosu \
    lxterminal \
    net-tools \
    openbox \
    procps \
    python3.8 \
    python3-pip \
    supervisor \
    tigervnc-standalone-server \
    unzip \
    wget \
    xdg-utils && \
    rm -rf /var/lib/apt/lists && \
    mkdir -p /usr/share/desktop-directories

RUN mkdir -p /usr/share/novnc && \
    cd /usr/share/novnc && \
    git clone https://github.com/novnc/noVNC.git && \
    cd noVNC && \
    git checkout 7485e82b72d4d1356d95ecca2d109cbf49908b9d && \
    mv * /usr/share/novnc/

COPY config/index.html /usr/share/novnc

RUN cd /usr/share/novnc/utils && git clone https://github.com/novnc/websockify websockify

RUN mkdir -p /tmp/.X11-unix
RUN chmod 1777 /tmp/.X11-unix

ENV SC_USER_NAME=scu
RUN groupadd --gid 8004 ${SC_USER_NAME} && \
    useradd --home-dir /home/${SC_USER_NAME} --shell /bin/bash --uid 8004 --gid 8004 ${SC_USER_NAME} && \
    mkdir -p /home/${SC_USER_NAME}

ENV DY_SIDECAR_PATH_INPUTS=/home/${SC_USER_NAME}/work/inputs
ENV DY_SIDECAR_PATH_OUTPUTS=/home/${SC_USER_NAME}/work/outputs

EXPOSE 12000
EXPOSE 8080

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

FROM base AS production

# TODO: Change according to your needs
RUN apt-get update -y && \
    apt-get install -y curl bzip2 libglib2.0-0 gcc menu libsdl1.2debian libsdl2-2.0-0 freeglut3 libgtk2.0-0 libnotify4 && \
    rm -rf /var/lib/apt/lists 

# Install sct
RUN git clone https://github.com/spinalcordtoolbox/spinalcordtoolbox.git sct && \
    cd sct && \
    ./install_sct -y

ENV PATH="/sct/bin:${PATH}"
ENV SCT_DIR=/sct


# Option 1: Install FSLeyes (for GUI part) using existing conda env
#RUN . /sct/python/etc/profile.d/conda.sh && \
#    conda activate venv_sct && \
#    conda create -c conda-forge -p fsleyes_env fsleyes "wxpython=4.0.*"
# Might be set to something different if necessary
# ENV FSLDIR=/fsleyes_env


# Option 2: Install FSLeyes (for GUI part) in a new virtual environment
#RUN apt-get install -y python3-venv

RUN pip install virtualenv
RUN virtualenv -p python3.8 /sct/fsleyes_env && \
#RUN python3 -m venv /sct/fsleyes_env && \
    . /sct/fsleyes_env/bin/activate && \
    pip install --upgrade pip && \
    pip install -f https://extras.wxpython.org/wxPython4/extras/linux/gtk2/ubuntu-18.04 wxpython && \
    pip install fsleyes

ENV PATH="/sct/fsleyes_env/bin:${PATH}"
ENV FSLDIR=/sct/contrib/fsl_integration

COPY config/menu.xml /etc/xdg/openbox/
COPY config/supervisord.conf /etc/

## workind directory and permissions
WORKDIR /home/scu/work
COPY docker/ /docker

CMD ["sh", "-c", "/docker/boot.sh"]
