#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
user_name="$USER"
no_wallpaper=false
dark_theme=true
firefox_theme=false

for arg in "$@"; do
  case "$arg" in
    -no-wp)
      no_wallpaper=true
      ;;
    -light)
      dark_theme=false
      ;;
    --firefox|-f)
      firefox_theme=true
      ;;
  esac
done

# Function to display usage
usage() {
  echo "Usage: $0 [install|update|uninstall|help] [-light] [-no-wp] [-f|--firefox]"
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
  "$script_dir"/WhiteSur-gtk-theme/tweaks.sh --firefox -r

  echo "Removing theme directories..."
  rm -rf "$script_dir"/WhiteSur-gtk-theme "$script_dir"/WhiteSur-icon-theme "$script_dir"/WhiteSur-cursors

  echo "Removing installed fonts..."
  for font in ~/.local/share/fonts/*; do
    if [[ $(basename "$font") == *"WhiteSur"* ]]; then
      rm -f "$font"
    fi
  done

  echo "Removing installed sounds..."
  rm -f ~/.local/share/sounds/WhiteSur-sounds

  echo "Removing wallpapers..."
  rm -f ~/Pictures/gnomintosh/

  echo "Resetting desktop background..."
  gsettings reset org.gnome.desktop.background picture-uri
  gsettings reset org.gnome.desktop.background picture-uri-dark

  # Cleaning previous directories
  echo "Cleaning directories..."
  rm -rf WhiteSur*

  echo "Uninstall completed."
  exit 0
}

update() {
  echo "Cleaning directories..."
  rm -rf WhiteSur*

  cloneRepositories
}

install() {
  cloneRepositories
}

cloneRepositories() {
  # Cloning required files
  echo "Cloning required files..."
  git clone https://github.com/jothi-prasath/WhiteSur-gtk-theme.git --depth=1
  git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
  git clone https://github.com/vinceliuice/WhiteSur-cursors.git --depth=1
  git clone https://github.com/lucagoc/MacOSSounds4Gnome.git  WhiteSur-sounds --depth=1
}

# Check for install/uninstall argument
if [[ "$1" == "uninstall" ]]; then
  uninstall
elif [[ "$1" == "update" ]]; then
  update
elif [[ "$1" == "install" ]]; then
  install
elif [[ "$1" == "help" ]]; then
  usage
fi

# Installing theme
echo "Run theme install..."
if [[ $dark_theme == false ]]; then
  "$script_dir"/WhiteSur-gtk-theme/install.sh -l -c Light
else
  "$script_dir"/WhiteSur-gtk-theme/install.sh -l -c Dark
fi

echo "Run theme tweaks..."

if [[ "$firefox_theme" == true ]]; then
  "$script_dir"/WhiteSur-gtk-theme/tweaks.sh --firefox
else
  "$script_dir"/WhiteSur-gtk-theme/tweaks.sh
fi

# Icons
echo "Run icons install..."
"$script_dir"/WhiteSur-icon-theme/install.sh -b

# Cursors
echo "Run cursors install..."
mkdir -p ~/.local/share/icons/WhiteSur-cursors
cp "$script_dir"/WhiteSur-cursors/dist/* ~/.local/share/icons/WhiteSur-cursors -prf

# Sounds
echo "Run sounds install..."
mkdir -p ~/.local/share/sounds/WhiteSur-sounds
cp "$script_dir"/WhiteSur-sounds/* ~/.local/share/sounds/WhiteSur-sounds -prf

if [[ "$no_wallpaper" == false ]]; then
  # Wallpapers
  echo "Run wallpaper install..."
  mkdir -p ~/Pictures/gnomintosh
  cp -r "$script_dir"/wallpaper/* ~/Pictures/gnomintosh
  gsettings set org.gnome.desktop.background picture-uri "file:///home/$user_name/Pictures/gnomintosh/ventura.jpg"
  gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/$user_name/Pictures/gnomintosh/monterey.png"
fi

# Load settings using dconf
echo "Run dconf load..."
dconf load / < "$script_dir"/dconf/settings.dconf
if [[ $dark_theme == false ]]; then
  dconf load / < "$script_dir"/dconf/light.dconf
else
  dconf load / < "$script_dir"/dconf/dark.dconf
fi

# Fonts
echo "Copy fonts..."
mkdir -p ~/.local/share/fonts/
cp "$script_dir"/fonts/* ~/.local/share/fonts/
