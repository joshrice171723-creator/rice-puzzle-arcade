const { getDefaultConfig } = require('expo/metro-config');
const config = getDefaultConfig(__dirname);
// Native build outputs and preserved dependency backups are not JavaScript sources.
config.resolver.blockList = [/[/\\]artifacts[/\\]/, /[/\\]android[/\\].*(?:[/\\]build[/\\]|[/\\]\.cxx[/\\])/];
module.exports = config;
