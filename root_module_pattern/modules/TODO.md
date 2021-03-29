## ToDo

- [ ] `cluster`, `network` ディレクトリを `gcp` ディレクトリにマージする
- [ ] `terraform_remote_state` から取得しているものを `resource` から直接取得するように変更
  - `module` からやめたほうが良さそう
  - これは Inject する方法がないから中間状態をを作るのが難しそう…
  - Module 化と module の統合は同時にやったほうがよさそう
