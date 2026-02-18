!# /bin/bash

sudo apt update
sudo apt install git


#clone repository in to default kicad templates
cd /usr/share/kicad/template
sudo chmod 777 ./
git clone https://github.com/nguyen-v/KDT_Hierarchical_KiBot.git


#goto dir
cd KDT_Hierarchical_KiBot

#copy fonts
sudo cp -r /kibot_resources/fonts /usr/local/share/

#copy color theme
sudo cp -r /kibot_resources/colors ~/.config/kicad/9.0/



#Kikit for simple automations

pipx install kikit
pipx ensurepath

