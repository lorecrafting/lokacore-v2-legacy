// The app bundles the unchanged kernel from ../ts/src/kernel (outside this project root).
const path = require('path');
const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);
config.watchFolders = [path.resolve(__dirname, '../ts/src/kernel')];
module.exports = config;
