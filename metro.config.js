const { getDefaultConfig } = require("expo/metro-config");

const defaultConfig = getDefaultConfig(__dirname);

module.exports = {
  ...defaultConfig,
  resolver: {
    ...defaultConfig.resolver,
    extraNodeModules: {
      ...defaultConfig.resolver.extraNodeModules,
    },
    assetExts: [...defaultConfig.resolver.assetExts, "pbf"], // Add "pbf" for tile files
    sourceExts: [...defaultConfig.resolver.sourceExts, "cjs"], // Add "cjs" for CommonJS modules
  },
};
