FROM ubuntu:noble

ENV CGO_ENABLED=1\
    GOOS=linux

# Dependencies
RUN apt-get update && apt-get install -y curl git gcc cpp npm libzmq3-dev pkg-config

# Install go
RUN curl -LO https://go.dev/dl/go1.23.4.linux-amd64.tar.gz && rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz && rm -rf go1.23.4.linux-amd64.tar.gz

# Clone zasper repo
RUN git clone https://github.com/zasper-io/zasper.git

# Build npm stuff
RUN npm config set registry http://registry.npmmirror.com
RUN cd zasper && cd ui && npm install react-scripts && npm audit fix --force || true
RUN cd zasper && cd ui && npm run build

# Build go
RUN cd zasper && export PATH=/usr/local/go/bin:$PATH && go build -tags webapp -o ui/public/zasper && cp ui/public/zasper /usr/local/bin

# Install sample python env
RUN apt-get install -y python3-pip
RUN pip config set global.index-url https://mirrors.aliyun.com/pypi/simple
RUN pip config set install.trusted-host mirrors.aliyun.com

RUN pip install jupyter --break-system-packages

RUN apt install python-is-python3
# Add user zasper
RUN useradd -m -s /bin/bash zasper
RUN echo "zasper:password" | chpasswd

# Run app under user zasper
USER zasper
WORKDIR /home/zasper
CMD /usr/local/bin/zasper
