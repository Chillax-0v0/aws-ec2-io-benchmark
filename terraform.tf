provider "aws" {
  region = "us-west-2"
}

provider "random" {}

resource "random_id" "hash" {
  byte_length = 8
}

resource "aws_vpc" "benchmark_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "EC2_IO_Benchmark_VPC_${random_id.hash.hex}"
    Benchmark = "EC2_IO"
  }
}

resource "aws_internet_gateway" "benchmark_internet_gateway" {
  vpc_id = aws_vpc.benchmark_vpc.id

  tags = {
    Benchmark = "EC2_IO"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.benchmark_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.benchmark_internet_gateway.id
}

resource "aws_subnet" "benchmark_subnet" {
  vpc_id                  = aws_vpc.benchmark_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"

  tags = {
    Benchmark = "EC2_IO"
  }
}

resource "aws_security_group" "benchmark_security_group" {
  name   = "ec2_io_${random_id.hash.hex}"
  vpc_id = aws_vpc.benchmark_vpc.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All ports open within the VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2_IO_Benchmark_SecurityGroup_${random_id.hash.hex}"
    Benchmark = "EC2_IO"
  }
}

resource "aws_key_pair" "benchmark_key_pair" {
  key_name   = "aws_ec2_io-${random_id.hash.hex}"
  public_key = file("~/.ssh/aws_ec2_io.pub")

  tags = {
    Benchmark = "EC2_IO"
  }
}

variable "instance_types" {
  type = list(object({
    instance_type = string
    arch          = string
  }))

  default = [
    {
      instance_type = "i3en.large"
      arch          = "x86_64"
    },
    {
      instance_type = "i3en.xlarge"
      arch          = "x86_64"
    },
    {
      instance_type = "i4i.large"
      arch          = "x86_64"
    },
    {
      instance_type = "i4i.xlarge"
      arch          = "x86_64"
    },
    {
      instance_type = "i4g.large"
      arch          = "arm64"
    },
    {
      instance_type = "i4g.xlarge"
      arch          = "arm64"
    },
    {
      instance_type = "is4gen.medium"
      arch          = "arm64"
    },
    {
      instance_type = "is4gen.large"
      arch          = "arm64"
    },
    {
      instance_type = "is4gen.xlarge"
      arch          = "arm64"
    },
    {
      instance_type = "im4gn.large"
      arch          = "arm64"
    },
    {
      instance_type = "im4gn.xlarge"
      arch          = "arm64"
    },
  ]
}

resource "aws_instance" "ec2_io" {
  count                  = length(var.instance_types)
  instance_type          = var.instance_types[count.index].instance_type
  ami                    = var.instance_types[count.index].arch == "x86_64" ? "ami-03f65b8614a860c29" : "ami-0c79a55dda52434da"
  key_name               = aws_key_pair.benchmark_key_pair.id
  subnet_id              = aws_subnet.benchmark_subnet.id
  vpc_security_group_ids = [aws_security_group.benchmark_security_group.id]

  tags = {
    Name      = "ec2_io_${count.index}"
    Benchmark = "EC2_IO"
  }
}
