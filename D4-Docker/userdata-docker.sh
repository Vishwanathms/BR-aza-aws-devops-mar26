#!/bin/bash

sudo dnf install docker -y 

sudo usermod -aG docker $USER
newgrp docker 

sudo systemctl status docker
sudo systemctl start docker
sudo systemctl enable docker