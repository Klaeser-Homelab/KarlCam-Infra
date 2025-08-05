all:
  children:
    k3s_cluster:
      children:
        control_plane:
          hosts:
%{ for node in control_plane_nodes ~}
            ${node.vm_name}:
              ansible_host: ${node.vm_ip}
              k3s_control_node: true
              node_id: ${node.vm_id}
%{ endfor ~}
        workers:
          hosts:
%{ for node in worker_nodes ~}
            ${node.vm_name}:
              ansible_host: ${node.vm_ip}
              node_id: ${node.vm_id}
%{ endfor ~}
      vars:
        ansible_user: ubuntu
        ansible_ssh_private_key_file: ~/.ssh/id_rsa
        ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
        
        # K3s Configuration
        k3s_version: v1.29.0+k3s1
        k3s_token: "{{ lookup('password', '/tmp/k3s_token_${cluster_name} length=32 chars=ascii_lowercase,digits') }}"
        k3s_cluster_cidr: 10.42.0.0/16
        k3s_service_cidr: 10.43.0.0/16
        
        # Cilium Configuration
        cluster_name: ${cluster_name}
        cluster_id: ${cluster_id}
        
        # KarlCam Configuration
        site_location: sf
        camera_range_start: 1
        camera_range_end: 18
        
    karlcam:
      children:
        k3s_cluster: {}