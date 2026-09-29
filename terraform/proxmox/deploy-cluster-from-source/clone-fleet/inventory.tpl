[fleet]
%{ for h in hosts ~}
${h.name} ansible_host=${h.ip} target_static_ip=${h.new_ip}
%{ endfor ~}

[fleet:vars]
ansible_user=${ssh_user}
ansible_password=${ssh_password}
ansible_become_password=${ssh_password}
target_interface=${interface}
target_netmask=${netmask}
target_gateway=${gateway}
target_dns=${dns}
