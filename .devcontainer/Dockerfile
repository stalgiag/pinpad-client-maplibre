FROM ubuntu:noble

# Install necessary dependencies
RUN apt update && apt install -y \
    yarnpkg \
    curl \
    wget \
    unzip \
    build-essential \
    ca-certificates \
    bash \
    git \
    zsh \
    vim \
    bvi \
    zip \
    adb \
    openjdk-11-jdk \
    && rm -rf /var/lib/apt/lists/* \
    && alias yarn=yarnpkg

# Create a non-root user with a home directory for better security
RUN groupadd -r devgroup && \
    useradd -m -r -g devgroup me

# Set the working directory
WORKDIR /home/me

# Ensure the workspace directory exists and is owned by me
RUN chown -R me:devgroup /home/me

# Switch back to root to install Android SDK
USER root

# Define Android SDK installation directory
ENV ANDROID_HOME=/home/me/Android/Sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# Create the cmdline-tools/latest directory
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools/latest

# Download and install Android SDK Command-Line Tools
RUN curl -o commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip commandlinetools.zip && \
    rm commandlinetools.zip && \
    # Move the contents of cmdline-tools into the latest directory to avoid nested cmdline-tools
    mv cmdline-tools/* ${ANDROID_HOME}/cmdline-tools/latest/ && \
    rm -rf cmdline-tools

# Ensure sdkmanager is executable
RUN chmod +x ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager

# Accept licenses and install essential SDK components
RUN yes | /home/me/Android/Sdk/cmdline-tools/latest/bin/sdkmanager --licenses && \
    /home/me/Android/Sdk/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"


USER me

# (Optional) Install Oh My Zsh for enhanced Zsh features
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Set a default theme and enable plugins in .zshrc (optional)
RUN echo 'export ZSH="$HOME/.oh-my-zsh"' >> ~/.zshrc && \
    echo 'ZSH_THEME="mrtazz"' >> ~/.zshrc && \
    echo 'plugins=(git)' >> ~/.zshrc && \
    echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc

RUN echo "alias -g yarn=yarnpkg" >> ~/.zshrc
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
