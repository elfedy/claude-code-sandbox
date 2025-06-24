FROM node:20

ARG TZ
ENV TZ="$TZ"

# Install basic development tools and firewall utilities
RUN apt update && apt install -y \
    less \
    git \
    procps \
    sudo \
    fzf \
    zsh \
    man-db \
    unzip \
    gnupg2 \
    gh \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    aggregate \
    jq \
    curl \
    wget \
    python3 \
    python3-pip \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Rust toolchain
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable && \
    chmod -R a+r $RUSTUP_HOME $CARGO_HOME && \
    chmod -R a+x $CARGO_HOME/bin && \
    rustup --version && \
    cargo --version && \
    rustc --version

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist command history and add claude alias
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc" \
    && echo "alias claude='claude --dangerously-skip-permissions'" >> "/home/$USERNAME/.bashrc"

# Create workspace and config directories
RUN mkdir -p /workspace /home/node/.claude && \
    chown -R node:node /workspace /home/node/.claude

# Copy firewall initialization script
COPY init-firewall.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-firewall.sh

# Configure sudo for firewall script
RUN echo 'node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh' >> /etc/sudoers

WORKDIR /workspace

# Install git-delta for better diffs
RUN ARCH=$(dpkg --print-architecture) && \
    wget "https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_${ARCH}.deb" && \
    dpkg -i "git-delta_0.18.2_${ARCH}.deb" && \
    rm "git-delta_0.18.2_${ARCH}.deb"

# Set up non-root user
USER node

# Configure npm and install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

RUN npm install -g @anthropic-ai/claude-code@latest

# Set the default shell to bash
ENV SHELL=/bin/bash

# Keep container running
CMD ["/bin/bash"]
