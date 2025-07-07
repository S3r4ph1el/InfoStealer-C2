# 🕵️‍♂️ InfoStealer and C2 Persistence

[![Status](https://img.shields.io/badge/Status-Educational%20Project-blue.svg)](https://www.unb.br/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

This repository presents an infostealer malware project with Command & Control (C2) infrastructure, developed for educational purposes in the **CyberSecurity Fundamentals** discipline at **UnB 2025.1**.

## 🎯 Project Objective

The main objective is to develop and implement a laboratory environment for simulating a cyberattack focused on **credential and sensitive data theft via Infostealer**, and maintaining **persistence through a C2 infrastructure**. The simulation aims to understand the dynamics of such attacks and propose **comprehensive solutions** (technical, operational, and procedural) for their detection, prevention, and mitigation.

This work was developed as part of the **CyberSecurity Fundamentals Seminar at UnB 2025.1**.

## ✨ Features

The project simulates a multi-stage attack, including the following key components:

* **HID Device Infection Vector (Simulated BadUSB):**
    * Simulates a USB drive that emulates a keyboard (BadUSB) to inject initial commands into the victim machine.
    * Injects commands to download and execute the Infostealer autonomously on the target machine.
* **Infostealer (Malicious Client):**
    * Developed in **Python** for multi-platform compatibility (Linux demonstrated).
    * Collects browser credentials (**Firefox**, **Chromium**).
    * Collects sensitive files (**.bash_history**, **SSH keys**).
    * Searches for **.txt** files containing keywords in their names.
    * Collects system information.
    * Exfiltrates complete files and collected information to the C2 via **HTTP POST**.
* **Command & Control (C2 Server):**
    * Implemented in **Flask (Python)**.
    * Receives and stores exfiltrated data, organized by victim ID and category.
    * Serves the `stealer_client.py` payload for download.
    * Allows the operator to send arbitrary commands to the Infostealer client, receiving the output.
    * Maintains client persistence.

## ⚙️ Lab Setup

HERE

## 🛡️ Detection and Mitigation Strategies

The project emphasizes proposing comprehensive solutions for detecting, preventing, and mitigating the simulated attack.

* **Technical Controls:** Firewall, EDR/Antivirus, OS hardening, log monitoring, network traffic analysis (IDS/IPS).
* **Operational Measures:** Incident Response Plan (IRP), threat hunting, backups.
* **Procedural Measures:** User awareness regarding social engineering and secure USB usage, USB device usage policies, principle of least privilege.

## ⚠️ Disclaimer

**This project is strictly for educational purposes within the CyberSecurity Fundamentals discipline at the University of Brasília (UnB 2025.1). It must not be used in production environments, real networks, or for any malicious activity. Misuse of this code is the sole responsibility of the user.**

---
