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

  echo "Just to make sure, remove firefox theme..."
  WhiteSur-gtk-theme/tweaks.sh --firefox -r

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

no_wallpaper=false
dark_theme=true
firefox_theme=false

# Controleer alle argumenten
for arg in "$@"; do
  case "$arg" in
    -no-wp)
      no_wallpaper=true
      ;;
    -light)
      dark_theme=false
      ;;
    --firefox_theme|-f)
      firefox_theme=true
      ;;
  esac
done

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
if [[ $dark_theme == false ]]; then
  WhiteSur-gtk-theme/install.sh -l -c Light
else
  WhiteSur-gtk-theme/install.sh -l -c Dark
fi
echo "Run theme tweaks..."

if [[ "$firefox_theme" == true ]]; then
  WhiteSur-gtk-theme/tweaks.sh --firefox
else
  WhiteSur-gtk-theme/tweaks.sh
fi

# Icons
echo "Run icons install..."
WhiteSur-icon-theme/install.sh -b

# Cursors
echo "Run cursors install..."
mkdir -p ~/.local/share/icons/WhiteSur-cursors
cp WhiteSur-cursors/dist/* ~/.local/share/icons/WhiteSur-cursors -prf

if [[ "$no_wallpaper" == false ]]; then
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
if [[ $dark_theme == false ]]; then
  dconf load / < dconf/light.dconf
else
  dconf load / < dconf/dark.dconf
fi

# Fonts
echo "Copy fonts..."
mkdir -p ~/.local/share/fonts/
cp fonts/* ~/.local/share/fonts/
