const xeScraper = require('./xe');
const wiseScraper = require('./wise');
const remitelyScraper = require('./remitely');

module.exports = {
  xe: xeScraper,
  wise: wiseScraper,
  remitely: remitelyScraper
};
