const { withDangerousMod } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

// This is necessary due to this issue in react-native-zip-archive: https://github.com/mockingbot/react-native-zip-archive/issues/305#issuecomment-2222293516
// Podfile installs are failing with the default deployment target of 15.1
// We cannot even set the deployment target in the Podfile.properties.json
// because Expo is overwriting the Podfile.properties.json with the default values
// This plugin sets the deployment target to 15.5 in the Podfile
const withIosDeploymentTarget = (config) => {
  return withDangerousMod(config, [
    'ios',
    async (config) => {
      const podfilePath = path.join(config.modRequest.platformProjectRoot, 'Podfile');
      let podfileContent = fs.readFileSync(podfilePath, 'utf8');
      
      // Replace the platform line with our fixed version
      podfileContent = podfileContent.replace(
        /platform :ios.*/,
        'platform :ios, \'15.5\''
      );
      
      fs.writeFileSync(podfilePath, podfileContent);
      return config;
    },
  ]);
};

module.exports = withIosDeploymentTarget;