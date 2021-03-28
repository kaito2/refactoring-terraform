## 実行手順

`dev.tfvars` ファイルの `REPLACE_ME` を書き換える。

```
$ cd flat_pattern
$ bash ./scripts/create-tf-bucket.sh dev [YOUR_PROJECT_ID]

$ cd network
$ terraform init
$ terraform workspace new network
$ terraform workspace select network
$ terraform plan --var-file=dev.tfvars
$ terraform apply --var-file=dev.tfvars

$ cd ../cluster
$ terraform init
$ terraform workspace new cluster
$ terraform workspace select cluster
$ terraform plan --var-file=dev.tfvars
$ terraform apply --var-file=dev.tfvars
```
