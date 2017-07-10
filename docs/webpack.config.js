'use strict';

const ExtractTextPlugin = require("extract-text-webpack-plugin");
const webpack = require('webpack');

module.exports = {
    watch: true,
    context: __dirname + "/develop",
    entry: {
        main: "./main",
        translate: './translation'
    },
    output: {
        path: __dirname + "/public/dist",
        filename: "[name].js",
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
        new ExtractTextPlugin({
            filename: "[name].css",
            disable: false,
            allChunks: true
        }),
        new webpack.optimize.UglifyJsPlugin()
    ]

};

