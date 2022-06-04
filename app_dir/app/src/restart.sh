#!/bin/sh

sudo killall -9 node

forever start server.js 
