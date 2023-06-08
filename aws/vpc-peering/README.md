![Accessing Confluent Cloud console with VPC Peering on AWS](https://github.com/jshashwat93/confluent-cloud-proxy/blob/main/assets/aws-vpc-peering.png)

# Confluent Cloud Proxy Setup with AWS VPC Peering

This project contains Terraform scripts that help you setup an NGINX proxy on a bastion host within a peered AWS VPC. The purpose is to enable local access to the Confluent Cloud console for clusters using private networking like VPC peering or private endpoints.

## **Prerequisites**

Before you start, ensure you have the following setup:

- **Confluent Cloud AWS dedicated cluster with VPC peering on AWS.**
- **An AWS VPC** that is peered with your Confluent Cloud cluster where the bastion host will also reside.
- The VPC's **Route Table should have a route to Confluent Cloud CIDR**. This allows network traffic to reach the Confluent Cloud cluster. This step is a part of the peering setup process.
- The VPC's **Route Table shoudl also have a route to the internet (via an Internet Gateway), VPN tunnel, or the network from where local access is required**. This allows your local machine to connect to the bastion host.
- **[Terraform](https://www.terraform.io/downloads.html) installed on your local machine.**

## **Information Required**

Make sure you have the following information at hand before you begin:

- **AWS Access Key**: Your AWS access key ID.
- **AWS Secret Key**: Your AWS secret access key.
- **Your VPC ID**: The ID of the VPC that is peered with Confluent Cloud and where you're setting up the bastion host.
- **Your Route Table ID**: The ID of the route table with the required routes from the prerequisutes.
- **AWS Region Code**: The AWS region code (like 'us-east-1', 'eu-west-1') where your VPC is located and where the resources will be created.
- **A CIDR range**: A CIDR range for creating a new subnet for the EC2 bastion host.
- **Confluent Cloud Cluster Endpoint**: The endpoint for your Confluent Cloud cluster that can be found under Cluster Settings -> Endpoints -> Bootstrap Server. It looks like `pkc-xxxxx.aws.confluent.cloud`. Remember to exclude the last part of the bootstrap server (`:9092`) for your endpoint.


Once you have the above setup and information, you're ready to use the Terraform scripts in this directory to setup the NGINX proxy.

## **Steps**

1. **Navigate to the directory** for the Linux distribution of your choice for the bastion host. Options include Amazon Linux, Amazon Linux 2, Ubuntu, Red Hat, and Debian.
2. **Run `terraform init`** to initialize the Terraform working directory.
3. **Run `terraform apply`** to apply the changes required to reach the desired state of the configuration.
4. **Enter 'yes' to confirm** the apply step when prompted.
5. **Provide the requested information** from the "Information Required" section during the Terraform apply process..
6. Once the Terraform process completes, **configure DNS resolution on your *local machine***. (Note: Do not modify the DNS resolution on the EC2 bastion)
7. **Log in to Confluent Cloud**, go your Dedicated Cluster. Go to the "Topics" section and see if you're able to click "Create topic".
If you can click, your proxy has been successfully created and you can now access the Confluent Cloud console locally!
