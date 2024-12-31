# Use Ubuntu 20.04 as the base image
FROM ubuntu:20.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    ca-certificates \
    bash \
    git \
    zsh \
    vim \ 
    bvi \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user with a home directory for better security
RUN groupadd -r devgroup && \
    useradd -m -r -g devgroup devuser

# Set the working directory
WORKDIR /workspace

# Ensure the workspace directory exists and is owned by devuser
RUN chown -R devuser:devgroup /workspace

# Switch to the non-root user
USER devuser

# Set environment variables for NVM installation
ENV NVM_DIR=/home/devuser/.nvm
ENV NODE_VERSION=18.18.0

# Install NVM, Node.js, Yarn, and Expo CLI as devuser
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    bash -c "source $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default && \
    npm install -g yarn expo-cli"

# Add NVM and Node.js to PATH for subsequent commands
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Verify installations (optional, can be removed later)
RUN node -v && npm -v && yarn -v && expo --version

# Copy package.json and yarn.lock first to leverage Docker cache
COPY --chown=devuser:devgroup package.json yarn.lock ./

# Install project dependencies
RUN yarn install

# Copy the rest of the application code
COPY --chown=devuser:devgroup . .

# (Optional) Install Oh My Zsh for enhanced Zsh features
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Set a default theme and enable plugins in .zshrc (optional)
RUN echo 'export ZSH="$HOME/.oh-my-zsh"' >> ~/.zshrc && \
    echo 'ZSH_THEME="mrtazz"' >> ~/.zshrc && \
    echo 'plugins=(git)' >> ~/.zshrc && \
    echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc

# Set environment variable to ensure Expo DevTools listen on all network interfaces
ENV EXPO_DEVTOOLS_LISTEN_ADDRESS=0.0.0.0

# Expose necessary ports
# 19000 - Metro Bundler
# 19001 - Metro Bundler (Web)
# 19002 - Expo DevTools
# 8080  - Custom server (start:tiles)
EXPOSE 19000 19001 19002 8080

# Define the default command to start the Expo development server
CMD ["yarn", "start", "--tunnel"]
