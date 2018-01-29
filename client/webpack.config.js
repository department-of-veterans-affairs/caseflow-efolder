const _ = require('lodash');
const path = require('path');

const baseConfigs = require(
  '@department-of-veterans-affairs/caseflow-frontend-toolkit/config/getWebpackConfig'
)(__dirname, './src/index');

module.exports = _.merge(baseConfigs, {
  output: {
    path: path.resolve(__dirname, '..', 'app', 'assets', 'javascripts'),
    filename: 'react-app.js',
    library: 'efolderExpress'
  }
});
