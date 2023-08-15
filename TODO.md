### Token

- [ ] Twitter Token をセッションではなくてデータベースの User テーブルに保存するように変更する

### スケジューラー

- [ ] 実行履歴を成功・失敗を含めてデータベースに保存し、ユーザーが参照できるようにする

### RSS

- [ ] RSS 新規 設定された時間に、RSS フィードをチェックして更新があれば、ツイートする
- [ ] RSS 紹介 設定された時間に、RSS フィードからランダムに選んだ記事をツイートする

https://www.shichimaru.com/rss/blog/%E8%B3%AA%E5%B1%8B%E3%81%8C%E8%A7%A3%E8%AA%AC
https://www.shichimaru.com/rss/blog/%E4%B8%83%E3%81%A4%E5%B1%8B%E5%BF%97%E3%81%AE%E3%81%B6%E3%81%AE%E5%AE%9D%E7%9F%B3%E5%8C%A3

```sql
create table rss (
    id uuid primary key,
    user_id text,
    template text,
    url text not null,
    last_pub_date timestamptz,
    created_at timestamptz,
    updated_at timestamptz,
)
```

```sql
create table task_rss (
    id uuid primary key,
    user_id text,
    rss_id uuid references rss(id),
    tweet_at timestamptz,
    sun boolean,
    mon boolean,
    random boolean,
    enabled boolean,
    created_at timestamptz,
    updated_at timestamptz,
)
```

未ツイートの最新記事がある場合は、`random == false`とする。但し、複数の記事があっても、最新の物しか対象とならない。
既存の記事からランダムに選択してツイートしたい場合は、`random == true` とする。

##

メッセージ作成ページは/message に移動し、ホーム/には使い方などを表示する

## ユーザー登録

- Twitter と連携する
- Hasura 上の Session テーブルにアクセストークンとリフレッシュトークンんが保存される
- backend_endpoint にリダイレクトされ、
- クライアント画面にリダイレクトされる
- JS から/api/v1/get_jwt をコールする
  - JS から Hasura/getToken を
- Hasura 上の User テーブルに情報が無いので、anonymous 権限で JWT を発行する
- SPA を anonymous 権限の JWT で実行し、/register にリダイレクトする
- anonymous 権限なのでメールアドレス登録フォームを表示する
- メールアドレスを送信する
- anonymous 権限で Hasura の User テーブルにレコードをインサートする
  - id = gen_uuid_v4()
  - email = メールアドレス
  - confirmed = False
  - confirmed_at = null
  - code = 生成された 6 桁の確認コード
  - generated_at 生成日時　（有効期間 10 分）
- 同時にメールを該当アドレスに送信する
- SPA は/register で確認コード入力画面に遷移する
- ユーザーが確認コードを入力したら Action/registerUser をコールする
- 問題がなければ / へリダイレクトする。
