#!/bin/bash
# Start the DYD backend server (requires Node.js 24+)

cd "$(dirname "$0")/server"
npm install
npm start
