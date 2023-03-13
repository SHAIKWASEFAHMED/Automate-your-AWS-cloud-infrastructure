provider "aws" {
  region = "us-east-1"
  access_key = "AKIAQ7ZHODH3GQL7JTQF"
  secret_key = "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"
}
# 1.Create a VPC
resource "aws_vpc" "Prod_VPC" {
  cidr_block = "10.0.0.0/16"
}

# 2. CREATE A INTERNET GATEWAY

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.Prod_VPC.id
  tags = {
    Name = "Production"
  }

}

#3. CREATE CUSTOM ROUTE TABLE
resource "aws_route_table" "Prod_Route_Table" {
  vpc_id = aws_vpc.Prod_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Production"
  }
}

# 4. CREATE A SUBNET
resource "aws_subnet" "Subnet-1" {
  vpc_id     = aws_vpc.Prod_VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Prod_Subnet"
  }
}

#5. ASSOCIATE SUBNET WITH ROUTE TABLE
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.Subnet-1.id
  route_table_id = aws_route_table.Prod_Route_Table.id
}

#6. CREATE A SECURITY GROUP TO ALLOW PORT 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.Prod_VPC.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

#7. CREATE A NETWORK INTERFACE WITH AN IP IN THE SUBNET THAT WAS CREATED IN STEP 4
resource "aws_network_interface" "web_server_nic" {
  subnet_id       = aws_subnet.Subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

#8. CREATE AN ELASTIC IP TO THE NETWORK INTERFACE CREATED IN STEP 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web_server_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
    
}
#9. CREATE UBUNTU SERVER AND INSTALL/ENABLE APACHE 2
resource "aws_instance" "web_server_instance" {
  ami           = "ami-0557a15b87f6559cf" # us-east-1
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "Key-Terraform"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web_server_nic.id
  }
   
   user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            sudo bash -c 'echo Your Very First Web Server > /var/www/html/index.html'
            EOF

    tags= {
    Name = "Web-Server"
 }

}


#resource "aws_instance" "My_First_EC2_Terraform" {
 # ami           = "ami-0a017d8ceb274537d"
  #instance_type = "t3.micro"
  #tags = {
   # Name = "CentOS"
  #}

  
#}