variable "function_name" {
  description = "Lambda の関数名 (e.g. copy-to-partition-for-athena)"
}

variable "bucket_ids" {
  type        = list(string)
  description = "パーティションを組みたい S3 バケット ID のリスト"
}
