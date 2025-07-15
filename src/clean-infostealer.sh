#!/bin/bash

# Remove the persistent gnome-updater.py file
rm -f ~/.local/share/gnome-updater.py

# Stop the gnome-updater service (if running)
systemctl --user stop gnome-updater.service

# Disable the gnome-updater service
systemctl --user disable gnome-updater.service

# Remove the systemd service file
rm -f ~/.config/systemd/user/gnome-updater.service

# Reload systemd user daemon to reflect the changes
systemctl --user daemon-reload