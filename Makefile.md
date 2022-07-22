## init
必要なツールのインストール

## setup-alp
alpのセットアップ

## setup-pt-query-digest
pt-query-digestのセットアップ

## setup-node-exporter
node_exporterのセットアップ

## setup-prometheus
Prometheusのセットアップ

## alp
ログファイルを直接読み込んでアクセスログを集計</br>
(/var/log/nginx/access.log)

## alpsave
ログファイルから読み込んで集計したのち、dumpファイルを生成
何バイト読み込んだかを記録

dumpファイルの名前を指定する場合は `make alpsave ALP_DUMP_NAME=<file_name>` で実行

## alpload
dumpファイルから読み込んでアクセスログを集計

## slow-on
slow-queriesの集計を実行するよう設定

## slow-off
slow-queriesの集計を実行しないよう設定

## slow-show
slow-queriesの集計結果を表示

## help
Makefileのヘルプを表示
