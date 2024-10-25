resource "aws_iam_role" "flask_ec2_role" {
  name = "flask_ec2_role1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name   = "s3_access_policy1"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["s3:ListBucket", "s3:GetObject"],
        Effect   = "Allow",
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.flask_ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "flask_instance_profile" {
  name = "flask-instance-profile1"
  role = aws_iam_role.flask_ec2_role.name
}
