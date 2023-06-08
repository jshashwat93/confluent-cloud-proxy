output "dns_configuration_steps" {
  description = "Steps to configure DNS resolution on your local computer"
  value = <<-EOT
    To configure DNS resolution on your local computer, follow these steps:
    
    1. Open your hosts file by running the following command:
       
       sudo vi /etc/hosts
       
       
    2. Add the following entry to the file:
       
       ${aws_instance.amazon_linux.public_ip} ${var.confluent_cloud_endpoint}

       This DNS entry has been dynamically generated to include your Bastion IP address and cluster endpoint, and should be added to your host file as rendered above.

 
   3. Save the file and exit the text editor.
  EOT
}