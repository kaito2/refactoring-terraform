## Refactoring Terraform Modules

1. `flat_pattern`: 複数の state に分かれてしまっている
1. `merged_pattern`: `flat_pattern` にあった複数の state を 1 つにまとめたパターン
1. `root_module_pattern`: `merged_pattern` で作成したディレクトリを Root module から参照しているパターン

### 目的

`flat_pattern` ですでに運用されている想定の Terraform をリファクタリングして、 `root_module_pattern` に移行する。

### 手順

レポジトリ内の `YOUR_GCP_PROJECT_ID` はすべて自分の GCP Project ID に置き換えてすすめる。

#### `flat_pattern` ディレクトリを apply する

Remote state 用のバケットを作成する。

```
$ cd flat_pattern
$ bash ./scripts/create-tf-bucket.sh dev [YOUR_GCP_PROJECT_ID]
```

```
$ cd network
$ terraform init
$ terraform workspace new network
$ terraform workspace select network
$ terraform plan --var-file=dev.tfvars
$ terraform apply --var-file=dev.tfvars
```

続いて `cluster` ディレクトリを apply する。
同じく `dev.tfvars` の値は置き換えておく。

```
$ cd ../cluster
$ terraform init
$ terraform workspace new cluster
$ terraform workspace select cluster
$ terraform plan --var-file=dev.tfvars
$ terraform apply --var-file=dev.tfvars
```

### `merged_pattern` ディレクトリに state を移行

`flat_pattern` ディレクトリの中身を `merged_pattern` ディレクトリのようにリファクタリングしたとう状況を想定して、`flat_pttern` の terraform state を `merged_pattern` に移行する。

こちらも `merged_pattern/merged/dev.tfvars` ファイルの `YOUR_GCP_PROJECT_ID` を書き換える。

```
$ cd ../../merged_pattern/merged
$ terraform init
$ terraform workspace new merged
$ terraform workspace select merged
```

この段階では Plan してもすべてのリソースが新規作成になる。

```
$ terraform plan --var-file=dev.tfvars
```

Remote state をローカルに取ってくる。

```
$ terraform state pull > merged.tfstate
```

`flat_pattern` で作成したリソースの state を取得して `merged.tfstate` にまとめる。

※ まとめる方法は [fujiwara/tfstate-merge](https://github.com/fujiwara/tfstate-merge) の使用を検討したが、 `0.14` に未対応のため、ひとまず手動で実施する。

TODO: まとめる方法(e.g. `terraform_remote_state` への参照ををリソースの参照に変更する)

```
# cluter の state を取得
$ terraform workspace select cluster ../../flat_pattern/cluster
$ terraform -chdir=../../flat_pattern/cluster state pull > tmp_cluster.tfstate

# network の state を取得
$ terraform workspace select network ../../flat_pattern/network
$ terraform -chdir=../../flat_pattern/network state pull > tmp_network.tfstate

# 手動で tmp_cluster.tfstate と tmp_network.tfstate の中身を merged.tfstate に移す
```

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
$ terraform init -reconfigure
$ terraform workspace select merged

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
$ diff -u merged.tfstate.before merged.tfstate.after
```

Plan しても差分が発生していないことを確認

```
$ terraform plan --var-file=dev.tfvars

...

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
Releasing state lock. This may take a few moments...
```

### `root_module_pattern` ディレクトリに state を移行

```
$ cd ../..

$ terraform -chdir=merged_pattern/merged state pull > merged_pattern/merged/merged.tfstate
$ cat << EOF > merged_pattern/merged/override.tf
terraform {
  backend "local" {
  }
}
EOF

$ cat << EOF > root_module_pattern/env/dev/override.tf
terraform {
  backend "local" {
  }
}
EOF

$ cd root_module_pattern/env/dev
$ terraform init
```

```
$ terraform state mv -state=../../../merged_pattern/merged/merged.tfstate -state-out=.terraform/terraform.tfstate \
  google_compute_network.vpc module.gcp.google_compute_network.vpc

$ terraform state mv -state=../../../merged_pattern/merged/merged.tfstate -state-out=.terraform/terraform.tfstate \
  google_compute_subnetwork.subnet module.gcp.google_compute_subnetwork.subnet

$ terraform state mv -state=../../../merged_pattern/merged/merged.tfstate -state-out=.terraform/terraform.tfstate \
  google_container_cluster.primary module.gcp.google_container_cluster.primary

$ terraform state mv -state=../../../merged_pattern/merged/merged.tfstate -state-out=.terraform/terraform.tfstate \
  google_container_node_pool.primary_nodes module.gcp.google_container_node_pool.primary_nodes
```

FIXME: Plan がぶっ壊れた。 `terraform state mv` ではなく、 `terraform ipmort` を使ったほうがいいかも知れない。

```
$ terraform plan -state=.terraform/terraform.tfstate

Error: Failed to load state: Terraform 0.14.4 does not support state version 4, please update.
```

`merged_pattern` を apply したところから再チャレンジ
何故か backend に `local` を指定すると state のバージョンが `3` になってしまうので `gcs` に `root-module` workspace を作って作業する。
TODO: state のバージョン問題は別途調査

```
$ cd ../..

$ terraform -chdir=merged_pattern/merged state pull > merged_pattern/merged/merged.tfstate
$ cat << EOF > merged_pattern/merged/override.tf
terraform {
  backend "local" {
  }
}
EOF

$ cd root_module_pattern/env/dev
$ terraform init
$ terraform workspace new root-module
$ terraform workspace select root-module
$ terraform state pull > root-module.tfstae
$ cat << EOF > override.tf
terraform {
  backend "local" {
  }
}
EOF

$ terraform workspace new root-module
$ terraform init -reconfigure

# 動作確認 (すべて新規作成になるはず)
$ terraform plan -state=root-module.tfstate
```

mv していく

```
$ terraform state mv -state=../../../merged_pattern/merged/merged.tfstate -state-out=root-module.tfstate \
  google_compute_network.vpc module.gcp.google_compute_network.vpc

$ terraform state mv -state=../../../merged_pattern/merged/merged.tfstate -state-out=root-module.tfstate \
  google_compute_subnetwork.subnet module.gcp.google_compute_subnetwork.subnet

$ terraform state mv -state=../../../merged_pattern/merged/merged.tfstate -state-out=root-module.tfstate \
  google_container_cluster.primary module.gcp.google_container_cluster.primary

$ terraform state mv -state=../../../merged_pattern/merged/merged.tfstate -state-out=root-module.tfstate \
  google_container_node_pool.primary_nodes module.gcp.google_container_node_pool.primary_nodes
```

Plan で差分がでないことを確認

```
$ terraform plan -state=root-module.tfstate
```

Remote に push する。
TODO: 本番ではもうちょい慎重なフローにする

```
$ rm override.tf
$ terraform init -reconfigure

$ terraform state push root-module.tfstate
$ terraform workspace select root-module
$ terraform plan
```

依存関係が残るので一応 apply しておく

```
$ terraform apply
```

TODO: apply 前後の state の比較
