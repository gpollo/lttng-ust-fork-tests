#!/bin/bash

sudo kill -KILL $(ps aux | grep -i lttng       | grep -v grep | grep -v vim | awk '{print $2}')
sudo kill -KILL $(ps aux | grep -i simple-fork | grep -v grep | grep -v vim | awk '{print $2}')

sudo rm -rf /home/gabriel/.lttng
sudo rm -rf /home/gabriel/lttng-traces

make clean
