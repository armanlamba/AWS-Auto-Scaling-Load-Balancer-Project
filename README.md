# AWS-Auto-Scaling-Load-Balancer-Project
This repository contains Terraform code to automate the setup of an AWS Auto Scaling group and an Application Load Balancer for a web server application hosted on Amazon EC2 instances

## Project Overview
This project is divided into two parts:

### Part A: Auto Scaling Group with a custom web server on Amazon Linux.
### Part B: Load Balancer setup to distribute traffic between three Microsoft Windows instances running IIS.

Diagrams

Part A: Auto Scaling Group with Web Server
![parta1](https://github.com/user-attachments/assets/3f478f4c-4cad-4bed-aa11-49b7f2c9eb82)

Part B: Load Balancer with IIS Web Servers
![partb1](https://github.com/user-attachments/assets/2793a3ac-a035-491e-974f-b6a9c4aad095)


## Requirements
- AWS Account (AWS Academy Sandbox)
- Terraform installed locally
- SSH key pair for connecting to EC2 instances
- Amazon Linux 2023 AMI for Part A
- Microsoft Windows Server 2019 AMI for Part B

## Infrastructure Overview
The infrastructure is created using Terraform and includes the following components:

- VPC: A new VPC with public and private subnets, spanning across multiple Availability Zones for high availability.
- EC2 Instances:
  - Part A: Amazon Linux EC2 instance with an auto scaling configuration.
  - Part B: Microsoft Windows instances running IIS web server.
- Auto Scaling Group: Automatically scales the number of Amazon Linux EC2 instances based on CPU utilization.
- Application Load Balancer: Distributes traffic between Windows IIS web servers in Part B.

## Part A: Auto Scaling Group with Amazon Linux
Steps:
1. Create VPC:

  - VPC with CIDR block 192.168.0.0/16.
  - Public and private subnets across different Availability Zones.
  
2. Launch EC2 Instances:

  - EC2 instance using Amazon Linux 2023 and instance type t2.micro.
  - SSH into the instance and install a web server (httpd for Apache).

3. Web Server Configuration:

The web server should display the message on the index page

4. Configure Auto Scaling:

  - Set the desired, minimum, and maximum number of instances for the Auto Scaling group:
    - Minimum = 2, Desired = 2, Maximum = 6.
  - Use a launch configuration based on the initially created EC2 instance.
  - Set the target CPU utilization for scaling at 5% (for testing purposes).

5. Load Testing:

You can test Auto Scaling by simulating high CPU usage with the following command on the running instance:

```shell
$ while true; do true; done

```
6. Application Load Balancer (ALB):
- ALB is optionally created to balance traffic between the EC2 instances in the Auto Scaling group.

## Part B: Application Load Balancer with IIS Web Servers

### Steps:

1. Provision EC2 Instances:

Create three Windows Server EC2 instances (VM1, VM2, and VM3) and install the IIS server role.
Configure each instance to display the instance name on the index page by editing the default IIS web page.
IIS setup commands:

```powershell
Install-WindowsFeature -name Web-Server -IncludeManagementTools
Remove-Item C:\inetpub\wwwroot\iisstart.html
Add-Content -Path "C:\inetpub\wwwroot\iisstart.html" -Value $("Hello World from " + $env:computername)
```

2. Configure Load Balancer:

- Set up an Application Load Balancer (ALB) to distribute incoming traffic between the three Windows IIS servers.
- Ensure the load balancer fetches content from one of the web servers on each page load.

3. Test the Setup:

- Open a web page on your browser and hit the load balancer's DNS URL.
- Verify that the load balancer distributes traffic to different web servers (VM1, VM2, and VM3) by refreshing the page multiple times.

## Terraform Setup
The Terraform code is already defined in the main.tf file. To deploy the infrastructure:

1. Clone this repository:

```bash
git clone https://github.com/armanlamba/AWS-Auto-Scaling-Load-Balancer-Project.git
cd https://github.com/armanlamba/AWS-Auto-Scaling-Load-Balancer-Project.git
```

2. Initialize Terraform:

```bash
terraform init
```

3. Apply the Terraform configuration:

```bash
terraform apply
```

4. Once the infrastructure is created, use the output details (instance IPs, ALB DNS name, etc.) to test the environment.

## Testing and Validation

Part A: Trigger Auto Scaling by simulating high CPU usage or adjusting the target value of CPU utilization to a low percentage.

Part B: Open multiple web pages to test the load balancing across the three IIS web servers.

## Cleanup

To avoid unnecessary charges, ensure to destroy the resources after testing:

```bash
terraform destroy
```
