#!/bin/bash

sudo kill -KILL $(ps aux | grep -i lttng       | grep -v grep | grep -v vim | awk '{print $2}')
sudo kill -KILL $(ps aux | grep -i ./simple    | grep -v grep | grep -v vim | awk '{print $2}')
sudo kill -KILL $(ps aux | grep -i ./same-pid  | grep -v grep | grep -v vim | awk '{print $2}')
sudo kill -KILL $(ps aux | grep -i ./recursive | grep -v grep | grep -v vim | awk '{print $2}')
sudo kill -KILL $(ps aux | grep -i ./run.sh    | grep -v grep | grep -v vim | awk '{print $2}')

sudo rm -rf ~/.lttng
sudo rm -rf ~/lttng-traces

make clean
