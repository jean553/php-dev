FROM unilynx/phusion-baseimage-1804:1.0.0

ENV SUDOFILE /etc/sudoers
ENV DEBIAN_FRONTEND noninteractive

COPY change_user_uid.sh /

RUN rm -f /etc/service/sshd/down && \
    echo 'PermitEmptyPasswords yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    useradd \
        --shell /bin/bash \
        --create-home --base-dir /home \
        --user-group \
        --groups sudo,ssh \
        --password '' \
        vagrant && \
    mkdir -p /home/vagrant/.ssh && \
    chown -R vagrant:vagrant /home/vagrant/.ssh && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install \
        sudo \
        git \
        python3-pip \
        php \
        php-xml \
    && \
    chmod u+w ${SUDOFILE} && \
    echo '%sudo   ALL=(ALL:ALL) NOPASSWD: ALL' >> ${SUDOFILE} && \
    chmod u-w ${SUDOFILE} && \
    apt-get clean && \
    pip3 install --upgrade ansible setuptools && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    touch -t 197001010000 /var/lib/apt/periodic/update-success-stamp && \
    sed -i '/tty/!s/mesg n/true/' /root/.profile

COPY provisioning/ /provisioning
RUN ansible-playbook provisioning/site.yml -c local
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    touch -t 197001010000 /var/lib/apt/periodic/update-success-stamp

ENTRYPOINT /change_user_uid.sh
CMD ["/sbin/my_init"]
