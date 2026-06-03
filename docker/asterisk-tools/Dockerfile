FROM andrius/asterisk:latest
RUN apt-get update -qq && apt-get install -y --no-install-recommends iproute2 tcpdump curl tshark \
    && rm -rf /var/lib/apt/lists/*
