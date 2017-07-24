'use strict';

const ExtractTextPlugin = require("extract-text-webpack-plugin");
const HtmlWebpackPlugin = require('html-webpack-plugin');
var WebpackChunkHash = require('webpack-chunk-hash');
var MD5HashPlugin = require('md5-hash-webpack-plugin');
const webpack = require('webpack');

module.exports = {
    // watch: true,
    context: __dirname + "/develop",
    entry: {
        main: "./main",
        translate: './translation'
    },
    output: {
        path: __dirname,
        filename: "./public/dist/[name].js?[chunkhash]",
        library: "[name]"
    },

    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /(node_modules)/,
                loader: "babel-loader",
                query: {
                    presets: ["es2015"]
                }
            },
            {
                test: /\.styl$/,
                use: ExtractTextPlugin.extract({
                    fallback: "style-loader",
                    use: ["css-loader", "stylus-loader"],
                    publicPath: "/"
                })
            }
        ]
    },
    plugins: [
        new WebpackChunkHash({algorithm: 'md5'}),
        new MD5HashPlugin(),
        new webpack.optimize.UglifyJsPlugin(),
        new ExtractTextPlugin({
            filename: "./public/dist/[name].css?[contenthash]",
            disable: false,
            allChunks: true
        }),
        new HtmlWebpackPlugin({
            hash: false,
            template: './index.html',
            inject: 'head'
        })
    ]
};

