FROM ubuntu:noble

RUN apt update && apt install -y \
    build-essential \
    ca-certificates \
    curl \
    unzip \
    bash \
    zsh \
    git \
    vim \
    # yarn package manager; yarn alias for yarnpkg created later in .zshrc
    yarnpkg \ 
    # bvi for viewing binary files; useful for inspecting tiles
    bvi \
    # zip for creating zip files
    zip \
    # Android Debug Bridge https://developer.android.com/tools/adb
    adb \
    openjdk-11-jdk

# Create a non-root user with a home directory for better security
RUN groupadd -r devgroup && \
    useradd -m -r -g devgroup me

WORKDIR /workspaces

# Install Android SDK
USER root
ENV ANDROID_HOME=/workspaces/Android/Sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools/latest
RUN curl -o commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip commandlinetools.zip && \
    rm commandlinetools.zip && \
    # Move the contents of cmdline-tools into the latest directory to avoid nested cmdline-tools
    mv cmdline-tools/* ${ANDROID_HOME}/cmdline-tools/latest/ && \
    rm -rf cmdline-tools
# Ensure sdkmanager is executable
RUN chmod +x ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager
# Accept licenses and install essential SDK components
RUN yes | /workspaces/Android/Sdk/cmdline-tools/latest/bin/sdkmanager --licenses && \
    /workspaces/Android/Sdk/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"


USER me
# Install Oh My Zsh for enhanced Zsh features
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
RUN echo 'export ZSH="$HOME/.oh-my-zsh"' >> ~/.zshrc && \
    echo 'ZSH_THEME="mrtazz"' >> ~/.zshrc && \
    echo 'plugins=(git)' >> ~/.zshrc && \
    echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc && \
    # create alias for yarn command
    echo "alias -g yarn=yarnpkg" >> ~/.zshrc && \
    # tell ADB client to communicate with server on host machine
    echo "export ADB_SERVER_SOCKET=tcp:host.docker.internal:5037" >> ~/.zshrc && \
    echo "adb kill-server" >> ~/.zshrc


# Set environment variable to ensure Expo DevTools listen on all network interfaces
ENV EXPO_DEVTOOLS_LISTEN_ADDRESS=0.0.0.0

# Expose necessary ports
# 19000 - Metro Bundler
# 19001 - Metro Bundler (Web)
# 19002 - Expo DevTools
# 8080  - Custom server (start:tiles)
EXPOSE 19000 19001 19002 8080