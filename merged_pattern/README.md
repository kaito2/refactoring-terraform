## 実行手順

`dev.tfvars` ファイルの `YOUR_GCP_PROJECT_ID` を書き換える。

```
$ cd merged_pattern

$ terraform init
$ terraform workspace new merged-pattern
$ terraform workspace select merged-pattern
```

`flat_pattern` で作成した `.tfstate` ファイルたちを取得する。

```
$ terraform workspace select cluster ../../flat_pattern/cluster
$ terraform -chdir=../../flat_pattern/cluster state pull > tmp_cluster.tfstate

$ terraform workspace select network ../../flat_pattern/network
$ terraform -chdir=../../flat_pattern/network state pull > tmp_network.tfstate
```

現状 `0.14` 系の Terraform の State をいい感じにマージするツールがないので、手動で `merged.tfstate` を作成する。

Plan を試すために backend を local に切り替える。
参考: [リモートの tfstate を書き換えずに安全に terraform state mv 後の plan 差分を確認する手順 - Qiita](https://qiita.com/minamijoyo/items/b4d70787556c83f289e7#backend%E3%82%92local%E3%81%AB%E5%88%87%E3%82%8A%E6%9B%BF%E3%81%88)

```
$ cat << EOF > override.tf
terraform {
  backend "local" {
  }
}
EOF

$ terraform workspace new merged
$ terraform workspace select merged
$ terraform init -reconfigure
```

Plan で差分がないことを確認

```
$ terraform plan -state=merged.tfstate --var-file=dev.tfvars

...

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

差分がないので `merged.tfstate` を remote に反映する。

```
$ rm override.tf
$ terraform workspace new merged
$ terraform workspace select merged
$ terraform init -reconfigure

# この時点では全部新規作成になっているはず
$ terraform plan --var-file=dev.tfvars

$ terraform state push merged.tfstate

# 今度は差分がなくなっているはず
$ terraform plan --var-file=dev.tfvars

# 一応 apply する
$ terraform apply --var-file=dev.tfvars
```

push した `.tfstate` ファイルと apply 後のファイルの差分を確認する。

```
$ mv merged.tfstate merged.tfstate.before
$ terraform state pull > merged.tfstate.after
```

Plan しても差分が発生していないことを確認

```
$ terraform plan --var-file=dev.tfvars
```
