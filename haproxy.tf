locals {
  ip_addrs           = "${var.datastore_cluster_id == "" ? vsphere_virtual_machine.haproxy.0.guest_ip_addresses : vsphere_virtual_machine.haproxy_ds_cluster.0.guest_ip_addresses}"
  haproxy_private_ip = "${contains(local.ip_addrs, element(var.private_ip_address, 0)) ? element(var.private_ip_address, 0) : ""}"
  haproxy_public_ip  = "${contains(local.ip_addrs, element(var.public_ip_address, 0)) ? element(var.public_ip_address, 0) : ""}"

  frontend_ports_list = "${jsonencode(var.frontend)}"
  backend_map         = "${jsonencode(var.backend)}"
}

resource "null_resource" "dependency" {
  triggers = {
    all_dependencies = "${join(",", var.dependson)}"
  }
}

module "install_haproxy" {
  source = "github.com/ibm-cloud-architecture/terraform-openshift-runplaybooks.git"

  triggerson = {
    lb = "${local.haproxy_private_ip}",
    frontend = "${local.frontend_ports_list}",
    backend = "${local.backend_map}"
  }

  dependson = "${
    list(null_resource.dependency.id)
  }"

  ansible_playbook_dir = "${path.module}/playbooks"
  ansible_playbooks = [
    "playbooks/haproxy.yaml"
  ]

  ansible_vars = {
    "frontend_ports" = "${local.frontend_ports_list}"
    "backends"       = "${local.backend_map}"
  }

  ssh_user        = "${var.template_ssh_user}"
  ssh_password    = "${var.template_ssh_password}"
  ssh_private_key = "${var.template_ssh_private_key}"

  bastion_ip_address      = "${var.bastion_ip_address}"
  bastion_ssh_user        = "${var.template_ssh_user}"
  bastion_ssh_password    = "${var.template_ssh_password}"
  bastion_ssh_private_key = "${var.template_ssh_private_key}"

  node_ips       = "${list(local.haproxy_private_ip)}"
  node_hostnames = "${list(local.haproxy_private_ip)}"

  //ansible_verbosity = "-vvv"

}
