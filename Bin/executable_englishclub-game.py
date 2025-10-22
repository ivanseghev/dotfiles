#!/usr/bin/env python3
import random
import os
# import subprocess
import webbrowser

# Path to your generated list
path = os.path.expanduser("~/Bin/englishclub_games.txt")

# KDE Connect device ID
PHONE_DEVICE_ID = "$PHONE_DEVICE_ID"

with open(path, encoding="utf-8") as f:
    lines = [line.strip() for line in f if line.strip()]

if not lines:
    raise SystemExit("No games found in list file.")

choice = random.choice(lines)
title, url = choice.rsplit(None, 1)
msg = f"{title}\n{url}"
webbrowser.open(url)

# --- Desktop notification
# subprocess.run([
#     "notify-send",
#     "--app-name=EnglishClub",
#     "--icon=applications-education",
#     "--expire-time=0",
#     title,
#     url
# ])

# --- Send to phone via KDE Connect (ping message)
# try:
#     subprocess.run([
#         "kdeconnect-cli",
#         "--device", PHONE_DEVICE_ID,
#         "--share", url
#     ])
# except Exception as e:
#     print("⚠️  KDE Connect notification failed:", e)

# --- Print to terminal
# print(f"Selected: {title}\n{url}")

