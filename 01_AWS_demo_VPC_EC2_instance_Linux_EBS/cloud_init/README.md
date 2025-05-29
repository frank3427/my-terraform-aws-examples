# Cloud-Init Scripts for EC2 Instance Initialization

## Purpose of this Directory

This directory (`cloud_init/`) stores user data scripts that are executed by [cloud-init](https://cloudinit.readthedocs.io/) when an EC2 instance boots for the first time. These scripts are used to perform initial configuration tasks, install software, and prepare the instance for its intended role.

In the context of the parent Terraform project (`01_AWS_demo_VPC_EC2_instance_Linux_EBS/`), these scripts typically handle:
*   Formatting and mounting an attached EBS volume.
*   Updating the system packages.
*   Installing common utility packages.
*   Other OS-specific configurations.

## Script Descriptions

This directory contains cloud-init scripts tailored for different Linux distributions:

*   **`cloud_init_al.sh`**:
    *   **Target OS:** Amazon Linux (typically Amazon Linux 2 or Amazon Linux 2023).
    *   **Common Actions:**
        *   Updates all system packages (`yum update -y`).
        *   Formats an attached EBS volume (e.g., `/dev/xvdb` or `/dev/sdb`) with the XFS filesystem.
        *   Creates a mount point (e.g., `/data`) and mounts the XFS volume.
        *   Adds an entry to `/etc/fstab` for persistent mounting.
        *   Installs common packages like `zsh`, `nmap`.
        *   May include installation of additional software like Docker (`amazon-linux-extras install docker -y` or `yum install docker -y`).

*   **`cloud_init_rhel.sh`**:
    *   **Target OS:** Red Hat Enterprise Linux (RHEL) and compatible distributions (e.g., CentOS, Rocky Linux, AlmaLinux).
    *   **Common Actions:**
        *   Updates all system packages (`yum update -y` or `dnf update -y`).
        *   Formats an attached EBS volume with XFS.
        *   Creates a mount point and mounts the XFS volume.
        *   Adds an entry to `/etc/fstab`.
        *   Installs common packages like `zsh`, `nmap`, `epel-release`.

*   **`cloud_init_sles.sh`**:
    *   **Target OS:** SUSE Linux Enterprise Server (SLES).
    *   **Common Actions:**
        *   Updates all system packages (`zypper refresh && zypper dup -y`).
        *   Formats an attached EBS volume with XFS.
        *   Creates a mount point and mounts the XFS volume.
        *   Adds an entry to `/etc/fstab`.
        *   Installs common packages like `zsh`, `nmap`.

*   **`cloud_init_ubuntu.sh`**:
    *   **Target OS:** Ubuntu Server.
    *   **Common Actions:**
        *   Updates package lists and upgrades installed packages (`apt update && apt upgrade -y`).
        *   Formats an attached EBS volume with XFS.
        *   Creates a mount point and mounts the XFS volume.
        *   Adds an entry to `/etc/fstab`.
        *   Installs common packages like `zsh`, `nmap`.

## Common Tasks Performed by these Scripts

While tailored for specific package managers and commands, most scripts in this directory aim to achieve the following:

1.  **EBS Volume Preparation:**
    *   Identify an attached EBS volume (often assumed to be `/dev/xvdb`, `/dev/sdb`, or a similar device name that isn't the root volume).
    *   Check if it's already formatted; if not, format it with the XFS filesystem (`mkfs.xfs`).
    *   Create a directory to serve as a mount point (commonly `/data` or `/mnt/data`).
    *   Mount the formatted XFS volume to this directory.
    *   Add an entry to `/etc/fstab` to ensure the volume is automatically mounted on subsequent reboots.
2.  **System Updates:**
    *   Update the package repositories and apply available updates to ensure the system is up-to-date.
3.  **Package Installations:**
    *   Install a set of common utility packages useful for system administration and diagnostics, such as:
        *   `zsh` (Z Shell)
        *   `nmap` (Network exploration tool and security scanner)
        *   `git` (Version control system)
        *   `telnet` (For basic port connectivity testing)
    *   The Amazon Linux script (`cloud_init_al.sh`) often includes steps to install Docker.
4.  **User Experience Enhancements (Sometimes):**
    *   May include minor shell configuration changes or setting up specific user environments, though this is less common in these generic scripts.

## Usage by Terraform

The Terraform configuration in the parent directory (e.g., in `03_ec2_instance.tf` or similar) is responsible for selecting and applying one of these cloud-init scripts to an EC2 instance during its launch. This is typically done using the `user_data` or `user_data_base64` argument within the `aws_instance` resource.

**Mechanism:**

1.  **Selection:** The choice of which script to use is often determined by a Terraform variable (e.g., `var.linux_os_version` or implicitly by the chosen `var.ami_id`). The Terraform configuration might use a `templatefile` function or a conditional lookup to select the appropriate script path.
2.  **Passing to EC2:**
    *   The content of the selected script is read by Terraform.
    *   It is then passed to the `user_data` argument of the `aws_instance` resource.
    *   Alternatively, if the script is templated with Terraform variables (not common for these particular scripts but possible), `templatefile` would render it, and then it might be passed to `user_data_base64` after being base64 encoded using `base64encode()`. However, for simple shell scripts, direct use of `user_data` with the script content is common.

When the EC2 instance launches, the cloud-init service on the instance executes the provided user data script, performing the defined initialization tasks. The output of the cloud-init process can typically be found in `/var/log/cloud-init-output.log` on the instance, which is useful for troubleshooting.
