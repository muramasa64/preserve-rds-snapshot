# preserve-rds-snapshot

Amazo RDSの自動バックアップによって作成されるスナップショット（automatedスナップショット）は、インスタンスが削除されたら消えてしまうので、それを manualスナップショットにコピーして保護することを目的としたスクリプトである。

automatedスナップショットは、RDSのBackup Windowの中で作成される。cronやタスクスケジューラなどを使って、Backup Windowの後にこのスクリプトを実行すれば、常に最新のコピーを作成することができる。

## 導入

Rubygemsのパッケージなので、gemコマンドでインストールできる。

```
$ gem install preserve-rds-snapshot
```

## AWS認証情報（credentials）

AWSの認証情報は、AWS CLIと同様に使用することができる。[thor-aws](http://github.com/y13i/thor-aws)を使っているので、詳細はそちらを参照のこと。EC2上で実行するのであれば、IAM Roleが利用できる。手元の環境で実行するのであれば、--profileがおすすめ。

## 初期化

まずは、対象となるRDSインスタンスを初期化する。

```
$ preserve-rds-snapshot init --region ap-northeast-1 --generations 5 --instance my-rds
```

`--instance` オプションでインスタンスを指定しなかった場合は、指定したリージョンの全てのRDSインスタンスが対象となる。その他のサブコマンドも全て同様。

`--generations` オプションは、スナップショットを残す世代数となる。 automatedスナップショットと違い、 manualスナップショットは自動的に削除されないため、新しくコピーを作成した際に、指定した世代数を超えた分のスナップショットを削除するようになっている。指定しなかった場合は10となる。

初期化処理は、RDSインスタンスに `preserve-rds-snapshot` タグを付与する。値には指定した世代数が入る。

## 実行

スナップショットをコピーする。

```
$ preserve-rds-snapshot preserve --region ap-northeast-1 --instance my-rds
```

preserveサブコマンドは、 `preserve-rds-snapshot` タグが付与されているインスタンスの、 automated スナップショットのうち、最新のスナップショットをコピーする。コピーする際には、インスタンスと同様に `preserve-rds-snapshot` タグを付与する。

コピー後、 `preserve-rds-snapshot` タグが付与されたスナップショットのうち、指定の世代数を超えた分のスナップショットを、snapshot create timeの古いものから削除する。

automatedスナップショットは、Backup Windowに合わせて毎日作成されるので、このスクリプトも、それに合わせて毎日実行される想定となっている。

## その他

最新のスナップショット以外を対象にしたい場合は、copyサブコマンドが使える。対象となるスナップショットを指定すれば良い。

あるスナップショットを、自動削除の対象外にしたい場合は、 `preserve-rds-snapshot` タグを削除すれば良い。

タグを生成する際に、AWSアカウント番号を使用する（対象のARNが必要となる）。そのため、EC2のセキュリティグループからAWSアカウント番号を取得している。EC2のDescribeSecurityGroups APIを実行する権限が必要となる（[参考](http://muramasa64.fprog.org/diary/?date=20141208)）。もし権限が付与できない場合は、`--aws-account-number` オプションを付与すること。

### 使用する AWS API

* RDS
  * describe_db_instances
  * describe_db_snapshots
  * copy_db_snapshot
  * delete_db_snapshots
  * list_tags_for_resources
  * add_tags_to_resources
  * remove_tags_from_resources
* EC2
  * describe_security_groups

註: describe_security_groupsはAWS Account Numberを取得するのに利用する。 `--aws-account-number` オプションに値を渡せば、describe_security_groupsの実行権限は不要。

## コマンド一覧

```
Commands:
  preserve-rds-snapshot copy -o src -t target  # copy snapshot
  preserve-rds-snapshot help [COMMAND]         # Describe available commands or one specific command
  preserve-rds-snapshot init                   # initialize instance
  preserve-rds-snapshot latest                 # show latest snapshot
  preserve-rds-snapshot list                   # Show list of RDS Snapshots
  preserve-rds-snapshot preserve               # copy automated snapshot to manual

Options:
  p, [--profile=PROFILE]                                   # Load credentials by profile name from shared credentials file.
  k, [--access-key-id=ACCESS_KEY_ID]                       # AWS access key id.
  s, [--secret-access-key=SECRET_ACCESS_KEY]               # AWS secret access key.
  r, [--region=REGION]                                     # AWS region.
      [--shared-credentials-path=SHARED_CREDENTIALS_PATH]  # AWS shared credentials path.
  i, [--instance=INSTANCE]                                 # target DB Instance
  n, [--aws-account-number=AWS_ACCOUNT_NUMBER]             # AWS Account Number (ex: 012345678901)
      [--dry-run], [--no-dry-run]                          # show only, don't modify
 ```
