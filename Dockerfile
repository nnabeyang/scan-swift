FROM swift:5.6.0-focal
WORKDIR /build
COPY Tools Tools
COPY build_tools.sh .
RUN bash build_tools.sh
RUN find ./ -type f -name swift-format | awk '{print "cp " $1 " /usr/bin"}' | bash
RUN rm -rf /build
ARG USERNAME=user
ARG GROUPNAME=user
ARG UID=1000
ARG GID=1000
ARG PASSWORD=user
RUN groupadd -g $GID $GROUPNAME && \
    useradd -m -s /bin/bash -u $UID -g $GID -G sudo $USERNAME && \
    echo $USERNAME:$PASSWORD | chpasswd && \
    echo "$USERNAME   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER $USERNAME
WORKDIR /home/$USERNAME/scan-swift