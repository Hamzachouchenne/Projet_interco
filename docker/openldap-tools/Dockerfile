FROM osixia/openldap:1.5.0
RUN sed -i \
    -e 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' \
    -e 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
    -e 's|http://ftp.debian.org/debian|http://archive.debian.org/debian|g' \
    -e '/buster-updates/d' \
    -e '/buster-backports/d' \
    /etc/apt/sources.list && \
    DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Check-Valid-Until=false update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tcpdump curl tshark \
    && rm -rf /var/lib/apt/lists/*
