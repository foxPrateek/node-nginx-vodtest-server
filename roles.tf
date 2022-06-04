
resource "aws_iam_role_policy_attachment" "basic_execution" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    role = aws_iam_role.app_server_role.name
}

data "aws_iam_policy_document" "lambda_job_trust" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
}

data "aws_iam_policy_document" "mediaconvert_job_trust" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
        type        = "Service"
        identifiers = ["mediaconvert.amazonaws.com"]
        }
    }
}

data "aws_iam_policy_document" "ec2_job_trust" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
        }
    }
}


resource "aws_iam_role_policy_attachment" "dynamodb_access" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    role = aws_iam_role.app_server_role.name
}


resource "aws_iam_role" "mediaconvert_role" {
    name = "m_server_role"
    assume_role_policy = data.aws_iam_policy_document.mediaconvert_job_trust.json
}

resource "aws_iam_role" "lambda_role" {
    name = "l_server_role"
    assume_role_policy = data.aws_iam_policy_document.lambda_job_trust.json
}

resource "aws_iam_role" "ec2_role" {
    name = "ec2_server_role"
    assume_role_policy = data.aws_iam_policy_document.ec2_job_trust.json
}

resource "aws_iam_instance_profile" "ec2_profile" {

name = "ec2_app_server_profile"
role = aws_iam_role.app_server_role.name 
lifecycle {
    create_before_destroy = true # or false
  }


}

resource "aws_iam_role" "app_server_role" {
    name = "app_server_role"
    //force_destroy = true
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "mediaconvert.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]

}
EOF


}

resource "aws_iam_role_policy" "app_server_policy" {
    name = "appserver--policy"
    role = aws_iam_role.app_server_role.id
    
    policy = data.aws_iam_policy_document.access_s3_policy_document.json
}
/*resource "aws_iam_role_policy_attachment" "mediacovert-and-s3-role" {
  role       = aws_iam_role.app_server_role.name
  policy_arn = aws_iam_policy.mediacovert-and-s3.arn
}

resource "aws_iam_policy" "mediacovert-and-s3" {
  name   = "mediacovert-and-s3-policy"
  policy = data.aws_iam_policy_document.access_s3_policy_document.json

}
*/
data "aws_iam_policy_document" "access_s3_policy_document" {
    statement {
        effect = "Allow"
        actions = [
            "mediaconvert:*"
        ]
        resources = ["*"]
    }

    statement {
        effect = "Allow"
        actions = [ "s3:*" ]
        resources = [
            "arn:aws:s3:::${var.input_bucket_name}",
            "arn:aws:s3:::${var.input_bucket_name}/*",
            "arn:aws:s3:::${var.app_data_bucket_name}", 
            "arn:aws:s3:::${var.app_data_bucket_name}/*"
             
        ]
    }

    statement {
        effect = "Allow"
        actions = [
            "s3:PutObject"
        ]
        resources = [
            "arn:aws:s3:::${var.output_bucket_name}",
            "arn:aws:s3:::${var.output_bucket_name}/*"
        ]
    }
   /*statement {
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            aws_iam_role.ec2_role.arn
        ]
    }*/
}



