FROM ubuntu/bind9:latest
RUN apt-get update -qq && apt-get install -y --no-install-recommends tcpdump curl tshark \
    && rm -rf /var/lib/apt/lists/*
