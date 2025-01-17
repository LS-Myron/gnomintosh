#!/usr/bin/env bash

user_name="$USER"

# Function to display usage
usage() {
  echo "Usage: $0 [install|uninstall] [-light] [-no-wp]"
  exit 1
}

# Function to uninstall the theme
uninstall() {
  read -p "Are you sure you want to uninstall WhiteSur theme? (y/N): " confirm
  if [[ "$confirm" != [yY] ]]; then
    echo "Uninstallation aborted."
    exit 0
  fi

  echo "Removing theme directories..."
  rm -rf ~/WhiteSur-gtk-theme ~/WhiteSur-icon-theme ~/WhiteSur-cursors

  echo "Removing installed fonts..."
  for font in ~/.local/share/fonts/*; do
    if [[ $(basename "$font") == *"WhiteSur"* ]]; then
      rm -f "$font"
    fi
  done

  echo "Removing wallpapers..."
  rm -f ~/Pictures/monterey.png

  echo "Resetting desktop background..."
  gsettings reset org.gnome.desktop.background picture-uri
  gsettings reset org.gnome.desktop.background picture-uri-dark

  echo "Uninstall completed."
  exit 0
}

# Cleaning previous directories
echo "Cleaning directories..."
rm -rf WhiteSur*

# Check for install/uninstall argument
if [[ "$1" == "uninstall" ]]; then
  uninstall
elif [[ "$1" != "install" ]]; then
  usage
fi

# Cloning required files
echo "Cloning required files..."
git clone https://github.com/jothi-prasath/WhiteSur-gtk-theme.git --depth=1
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
git clone https://github.com/vinceliuice/WhiteSur-cursors.git --depth=1

# Installing theme
echo "Run theme install..."
if [[ -f "$2" || "$2" == '-light' ]]; then
  WhiteSur-gtk-theme/install.sh -l -c Light
else
  WhiteSur-gtk-theme/install.sh -l -c Dark
fi
echo "Run theme tweaks..."
WhiteSur-gtk-theme/tweaks.sh

# Icons
echo "Run icons install..."
WhiteSur-icon-theme/install.sh -b

# Cursors
echo "Run cursors install..."
mkdir -p ~/.local/share/icons/WhiteSur-cursors
cp WhiteSur-cursors/dist/* ~/.local/share/icons/WhiteSur-cursors -prf


if [[ -f "$3" || "$3" != '-no-wp' ]]; then
  WhiteSur-gtk-theme/install.sh -l -c Light
  # Wallpapers
  echo "Run wallpaper install..."
  mkdir -p ~/Pictures/
  cp -r wallpaper/* ~/Pictures/
  gsettings set org.gnome.desktop.background picture-uri "file:///home/$user_name/Pictures/monterey.png"
  gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/$user_name/Pictures/monterey.png"
fi


# Load settings using dconf
echo "Run dconf load..."
dconf load / < dconf/settings.dconf
if [[ -f "$2" || "$2" == '-light' ]]; then
  dconf load / < dconf/light.dconf
else
  dconf load / < dconf/dark.dconf
fi

# Fonts
echo "Copy fonts..."
cp fonts/* ~/.local/share/fonts/
