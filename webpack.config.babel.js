// webpack.config.js
require('./babel-register');
const path = require('path');

module.exports = {
  entry: './src/read3DAO.js', // Replace with the path to your entry JavaScript file
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
  },
  devServer: {
    contentBase: path.resolve(__dirname, 'dist'),
    watchContentBase: true,
    headers: {
      'Content-Type': 'application/javascript', // Set the correct MIME type for JavaScript files
    },
  },
  module: {
    rules: [
      {
        test: /\.m?js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env'],
          },
        },
      },
    ],
  },
};
