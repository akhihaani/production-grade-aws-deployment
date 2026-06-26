variable "tags" {
  type = map(string)
}

variable "memos_alb_sg" {
  type = string
}

variable "memos_public_subnets" {
  type = list(string)
}

variable "memos_vpc" {
  type = string
}

variable "memos_cert_valid" {
  type = string
}

variable "memos_lb_logs" {
  type = string
}