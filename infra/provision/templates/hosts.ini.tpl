[cloud1]
%{ for i,ip in public_ips ~}
cloud1-${i} ansible_host=${ip} ansible_user=ubuntu ansible_ssh_private_key_file=${ssh_private_key_path}
%{ endfor ~}