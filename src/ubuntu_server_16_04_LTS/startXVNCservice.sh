#!/bin/sh

Xvfb :1 -screen 0 1024x786x16 &

x11vnc -sleepin 5 -display :1 -bg -forever -shared -nopw -listen localhost -xkb