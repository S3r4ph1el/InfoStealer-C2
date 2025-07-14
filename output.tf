output "vm_victim_ip" {
  value = aws_instance.vm_victim.public_ip
}

output "vm_wazuh_ip" {
  value = aws_instance.vm_wazuh.public_ip
}

output "vm_attacker_ip" {
  value = aws_instance.vm_attacker.public_ip
}

output "vm_victim_private_ip" {
  value = aws_instance.vm_victim.private_ip
}

output "vm_wazuh_private_ip" {
  value = aws_instance.vm_wazuh.private_ip
}

output "vm_attacker_private_ip" {
  value = aws_instance.vm_attacker.private_ip
}