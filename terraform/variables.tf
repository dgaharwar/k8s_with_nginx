// AWS config variables
variable "access_key" {
  default = ""
}

variable "secret_key" {
  default = ""
}


variable "INSTANCE_NAME" {
  default = "mam4pro-cloudsail"
}
variable "SERVICES_CAPTURE_HD_REPLICAS" {
  default = "0"
}
variable "SERVICES_CAPTURE_FHD_REPLICAS" {
  default = "1"
}
variable "SERVICES_CAPTURE_4K_REPLICAS" {
  default = "0"
}
variable "SERVICES_TRANSCODER_HD_REPLICAS" {
  default = "0"
}
variable "SERVICES_TRANSCODER_FHD_REPLICAS" {
  default = "0"
}
variable "SERVICES_TRANSCODER_4K_REPLICAS" {
  default = "0"
}
variable "SERVICES_INGEST_HD_REPLICAS" {
  default = "1"
}
variable "SERVICES_INGEST_FHD_REPLICAS" {
  default = "0"
}
variable "SERVICES_INGEST_4K_REPLICAS" {
  default = "0"
}
variable "SERVICES_PLAYER_HD_REPLICAS" {
  default = "2"
}
variable "SERVICES_PLAYER_FHD_REPLICAS" {
  default = "0"
}
variable "SERVICES_PLAYER_4K_REPLICAS" {
  default = "0"
}

variable "SERVICES_DISTRIBUTOR_HD_REPLICAS" {
  default = "0"
}
variable "SERVICES_DISTRIBUTOR_FHD_REPLICAS" {
  default = "0"
}
variable "SERVICES_DISTRIBUTOR_4K_REPLICAS" {
  default = "0"
}


