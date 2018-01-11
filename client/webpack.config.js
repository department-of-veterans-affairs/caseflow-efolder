const path = require('path');

module.exports = {
  entry: path.resolve(__dirname, 'src'),
  output: {
    path: path.resolve(__dirname, '..', 'app', 'assets', 'javascripts'),
    filename: 'react-app.js',
    library: 'efx'
  },
  resolve: {
    extensions: ['.js', '.jsx']
  },
  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        loader: 'babel-loader',
        exclude: /node_modules/
      }
    ]
  }
};
