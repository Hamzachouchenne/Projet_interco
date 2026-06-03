FROM osixia/phpldapadmin:0.9.0
RUN find /etc/apt/sources.list.d/ -name "nginx*" -delete && \
    echo "deb http://archive.debian.org/debian stretch main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list && \
    DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Check-Valid-Until=false update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tcpdump \
    && rm -rf /var/lib/apt/lists/*
