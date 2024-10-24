resource "aws_instance" "flask_ec2" {
  ami           = "ami-0dee22c13ea7a9a67" 
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.flask_sg.name]

  iam_instance_profile = aws_iam_instance_profile.flask_instance_profile.name

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "FlaskAppEC2Instance"
  }
}
