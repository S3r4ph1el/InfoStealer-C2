#!/bin/bash
set -e

# Check if the user provided the path to the private key
if [[ $# -ne 1 ]]; then
  echo "Missing argument: Path to the private key file is required."
  exit 1
fi

KEY_PATH="$1"

# Check if the provided key file exists
if [[ ! -f "$KEY_PATH" ]]; then
  echo "Error: private key file not found in '$KEY_PATH'"
  exit 1
fi





# 1. Apply Terraform configuration
terraform init
terraform apply -auto-approve


# 2. Get the public and private IPs of the VMs
VM_VICTIM_IP=$(terraform output -raw vm_victim_ip)
VM_PROTECTED_IP=$(terraform output -raw vm_protected_ip)
VM_WAZUH_IP=$(terraform output -raw vm_wazuh_ip)
VM_ATTACKER_IP=$(terraform output -raw vm_attacker_ip)
PRIVATE_IP_VICTIM=$(terraform output -raw vm_victim_private_ip)
PRIVATE_IP_PROTECTED=$(terraform output -raw vm_protected_private_ip)
PRIVATE_IP_WAZUH=$(terraform output -raw vm_wazuh_private_ip)
PRIVATE_IP_ATTACKER=$(terraform output -raw vm_attacker_private_ip)


# 3. Create the Ansible inventory file
cat > hosts <<EOF
[victim]
${VM_VICTIM_IP}
[protected]
${VM_PROTECTED_IP}
[wazuh]
${VM_WAZUH_IP}
[attacker]
${VM_ATTACKER_IP}
EOF

echo "'hosts' file generated:"
cat hosts


# 4. Create the Ansible configuration file
cat > ansible.cfg <<EOF
[defaults]
host_key_checking = False
remote_user = ubuntu
private_key_file = ${KEY_PATH}
EOF

echo "'ansible.cfg' file generated:"
cat ansible.cfg

# 5. Create the Ansible variables file
cat > ansible_vars.yaml <<EOF
---
victim_ip: "${PRIVATE_IP_VICTIM}"
protected_ip: "${PRIVATE_IP_PROTECTED}"
wazuh_ip: "${PRIVATE_IP_WAZUH}"
attacker_ip: "${PRIVATE_IP_ATTACKER}"
EOF

# 5. Runs Ansible playbook
ansible-playbook -i hosts playbook.yaml