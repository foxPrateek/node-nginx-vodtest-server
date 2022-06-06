

variable "input_bucket_name" {
    description = "Input bucket name which contains videos to be transcoded."
    default = "cpe-vod-input-bucket"
    type = string
}

variable "output_bucket_name" {
    description = "Output bucket name which contains videos after transcoding."
    default = "cpe-vod-output-bucket"
    type = string
}

variable "app_data_bucket_name" {

    default = "cpe-appserver-bucket"
    type = string

}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "ap-south-1"
}

variable "aws_ami" {
  description = "Amazon Machine Images."
  default = "ami-0756a1c858554433e"
}
variable "aws_type" {
  description = "Amazon Machine Images."
  default = "t3.medium"
}

variable "local_data_dir" {
  description = "Local data directory"
  default = "app_dir"

}
