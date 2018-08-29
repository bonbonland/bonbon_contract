const fs = require('fs')
const dotenv = require('dotenv')
const envConfig = dotenv.parse(fs.readFileSync(__dirname + '/../.env'))

module.exports = {
  envConfig: envConfig,
}