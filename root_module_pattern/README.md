## 実行手順

`dev.tfvars` ファイルの `YOUR_GCP_PROJECT_ID` を書き換える。

```
$ cd root_mosule_pttern/env/dev
$ terraform init
$ terraform plan
```

`Plan: 4 to add, 0 to change, 0 to destroy.` の差分がでていることを確認する。
State が空なので差分がある。

```
$ terraform workspace new root-module
$ terraform workspace select root-module
```

Remote bucket の `terraform/root-module.tfstate` ファイルができているのを確認する。

`flat_pattern` で作成した `.tfstate` を手元にダウンロードする。

```
$ gsutil cp gs://kaito2-flat-pattern-dev/terraform/root-module.tfstate .
$ gsutil cp gs://kaito2-flat-pattern-dev/terraform/cluster.tfstate .
$ gsutil cp gs://kaito2-flat-pattern-dev/terraform/network.tfstate .
```

ツールを使って `.tfstate` をマージする。

```
$ git clone git@github.com:fujiwara/tfstate-merge.git
$ ./tfstate-merge/tfstate-merge -i.bak root-module.tfstate cluster.tfstate network.tfstate
```

~作成した `root-module.tfstate` を remote bucket の `terraform/` ディレクトリにコピーする。~

`tfstate-merge` は `0.14` 系では動作していなさそう。

- MEMO: `terraform plan -state=root-module.tfstate` で指定しても remote state を参照しているっぽい(他にも設定すべき項目がある?)
  - [リモートの tfstate を書き換えずに安全に terraform state mv 後の plan 差分を確認する手順 - Qiita](https://qiita.com/minamijoyo/items/b4d70787556c83f289e7)
  - 単純に `flat_pattern` のディレクトリを結合しちゃったほうが良い?
    - [Detecting and Managing Drift with Terraform](https://www.hashicorp.com/blog/detecting-and-managing-drift-with-terraform)

```
$ terraform plan
```

全部作り直しになってしまう…
直接 `resource` として定義されるものと、 `moudle` 内の `resource` として定義されるものは別のものとして認識される。
`terraform state mv` を地道に書くしかなさそう。

## とりあえず apply してみる

```
$ cd root_module_pattern
$ cd env/dev
$ terraform init
$ terraform workspace new root-module
$ terraform workspace select root-module
$ terraform plan --var-file=dev.tfvars
```
