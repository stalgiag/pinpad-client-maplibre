#!/bin/sh
clear_bar="\n--------------------"
doit_generic="Okay, you should go do that. lmk when you're done."$clear_bar
confirm="Great!"$clear_bar
yn_no_default="[yN]: "
pass=""

no_default(){
    exit 1
}


instructions(){
    echo $clear_bar
    echo "Drift runs on Expo (https://expo.dev/)"
    echo "Expo is a React-based ecosystem for native apps."
    echo "That means it has a bunch of requirements!"
    echo "This script is to help the Drift team install all dependencies, because it has proven to be a pain in the ass. $clear_bar"
}


homebrew_install_prompt="Have you installed Homebrew? $yn_no_default"
homebrew_install_instructions="Read the install instructions here: https://brew.sh/ - easy!"
homebrew_not_installed() {
    :
}


nvm_install_prompt="Have you installed nvm? $yn_no_default"
nvm_install_instructions="Install nvm via the instructions here: https://github.com/nvm-sh/nvm"


nvm_config_prompt="Are you using node version 22.11.0?
(Hint: You can check by typing \`node -v\`) $yn_no_default"

nvm_config_instructions="Run \`nvm install 22.11.0\` in your terminal."


node_install_prompt="Have you installed Node? $yn_no_default"
node_install_instructions="Use the instructions here: https://nodejs.org/en/download"

yarn_install_prompt="Have you installed yarn? $yn_no_default"
yarn_install_instructions="View install instructions here: https://classic.yarnpkg.com/lang/en/docs/install/#mac-stable"

xcode_install_prompt="Have you installed XCode? $yn_no_default"
xcode_install_instructions="Install it here: https://apps.apple.com/us/app/xcode/id497799835?mt=12
Or if you fancy: 
\`brew install mas\`
\`mas search xcode\`
\`mas install 497799835\`"
#todo - https://www.moncefbelyamani.com/how-to-install-xcode-with-homebrew/

xcode_sim_prompt="Have you set up an XCode simulator yet? $yn_no_default"
xcode_sim_instructions="1. Go to XCode > Settings > Platform. 
2. Ensure 'iOS ([VERSION])' is downloaded
3. Go to Xcode > Open Developer Tool > Simulator
4. Add a Simulator under File > New Simulator."


android_install_prompt="Have you installed Android Studio? $yn_no_default"
android_install_instructions="Install here: https://developer.android.com/studio
or... \`brew install --cask android-studio\`
"

android_config_prompt="Have you configured Android Studio's simulator? $yn_no_default"
android_config_instructions="To set up a simulator, look under **Tools > Device Manager**"

expo_install_prompt="Have you installed Expo?"$yn_no_default
expo_install_instructions="Install here: https://github.com/expo/expo"


#echo "Have you installed yarn?"
#read yarn_install

ask_question(){
    # This function takes a question, and pipes a no response and action
    # To skip the action call "$pass" (aka `:`)
    local yn_question=$1
    local no_response=$2
    local no_action=$3
    local yes_response=$4
    local yes_action=$5

    read -p "$yn_question" yn

    # Check whether it's yes or no
    if [[ -z $yn ]]; then
        echo "$no_response"
        $no_action
        exit 1
    elif [[ $yn =~ ^[Yy]$ ]]; then
        echo "$yes_response"
        $yes_action
    elif [[ $yn =~ ^[Nn]$ ]]; then
        echo "$no_response"
        $no_action
        exit 1
    fi
}

instructions
ask_question "$homebrew_install_prompt" "$homebrew_install_instructions" homebrew_not_installed "$confirm" "$pass"
ask_question "$nvm_install_prompt" "$nvm_install_instructions" no_default "$confirm" "$pass"
ask_question "$nvm_config_prompt" "$nvm_config_instructions" no_default "$confirm" "$pass"
ask_question "$yarn_install_prompt" "$yarn_install_instructions" no_default "$confirm" "$pass"
ask_question "$xcode_install_prompt" "$xcode_install_instructions" "$pass" "$confirm" "$pass"
ask_question "$xcode_sim_prompt" "$xcode_sim_instructions" "$pass" "$confirm" "$pass"
ask_question "$android_install_prompt" "$android_install_instructions" "$pass" "$confirm" "$pass"
ask_question "$android_config_prompt" "$android_config_instructions" "$pass" "$confirm" "$pass"
#ask_question "$expo_install_prompt" "$expo_install_instructions" "$pass" "$confirm" "$pass"

