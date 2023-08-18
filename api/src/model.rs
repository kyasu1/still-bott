use crate::error::{Error, TwitterSnafu};
use derive_new::new;
use random_number::random;
use serde::{Deserialize, Serialize};
use snafu::prelude::*;
use std::future::Future;
use strum_macros::Display;
use time::OffsetDateTime;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Token {
    pub id: String,
    pub access_token: String,
    pub refresh_token: Option<String>,
    pub issued_at: OffsetDateTime,
    pub expires_in: Option<std::time::Duration>,
}

impl Token {
    pub fn from_session(
        id: String,
        access_token: String,
        refresh_token: Option<String>,
        expires_in: Option<i32>,
        issued_at: OffsetDateTime,
    ) -> Self {
        Self {
            id,
            access_token: access_token,
            refresh_token: refresh_token,
            expires_in: expires_in.map(|v| std::time::Duration::from_secs(v as u64)),
            issued_at,
        }
    }
}
//

#[derive(Serialize, Debug)]
#[serde(untagged)]
pub enum TweetJson {
    Tweet(Tweet),
    TweetWithMedia(TweetWithMedia),
}

#[derive(Serialize, Debug)]
pub struct Tweet {
    text: String,
}

#[derive(Serialize, Debug)]
pub struct TweetWithMedia {
    text: String,
    media: MediaIds,
}

#[derive(Serialize, Debug)]
pub struct MediaIds {
    media_ids: Vec<String>,
}

//
// Hasura上に登録されているユーザーを表す
//
#[derive(Debug, new, Clone)]
pub struct HasuraUser {
    pub id: String,
    pub email: String,
    pub role: Role,
    pub active: bool,
    pub last_seen: time::PrimitiveDateTime,
    // pub registered_at: time::PrimitiveDateTime,
    pub email_confirmed: bool,
    pub email_confirmed_at: Option<time::OffsetDateTime>,
    pub email_confirm_code: Option<String>,
    pub email_confirm_code_issued_at: Option<time::OffsetDateTime>,
}

#[derive(Serialize, Debug, Deserialize, Clone, Display)]
#[serde(rename_all = "lowercase")]

pub enum Role {
    // #[strum(serialize = "anonymous")]
    Anonymous,
    // #[strum(serialize = "basic")]
    Basic,
    // #[strum(serialize = "premium")]
    Premium,
}

#[derive(Debug, new, Clone)]
pub struct ActiveUser {
    pub user_id: String,
    pub tasks: Vec<EnabledTask>,
    pub rss_tasks: Vec<RssTask>,
}

#[derive(Deserialize, Serialize, Debug, new, Clone)]
pub struct Message {
    id: uuid::Uuid,
    user_id: String,
    text: String,
    media_id: Option<uuid::Uuid>,
    priority: i32,
    created_at: time::OffsetDateTime,
    updated_at: time::OffsetDateTime,
}

impl Message {
    pub async fn tweet<F, Fut>(&self, token: Token, send_tweet: F) -> Result<String, Error>
    where
        F: FnOnce(Token, serde_json::Value) -> Fut,
        Fut: Future<Output = Result<String, crate::twitter::Error>>,
    {
        tracing::debug!("{:?}", self);

        let json = match self.media_id {
            Some(media_id) => {
                let bucket_name = self.user_id.to_string();

                let bucket = crate::minio::get_or_create_bucket(&bucket_name)
                    .await
                    .context(crate::error::MinioSnafu)?;

                let media_id =
                    crate::twitter::twitter_v1_media_upload(self.user_id.clone(), media_id, bucket)
                        .await
                        .context(crate::error::TwitterSnafu)?;

                TweetJson::TweetWithMedia(TweetWithMedia {
                    text: self.text.clone(),
                    media: MediaIds {
                        media_ids: vec![media_id.to_string()],
                    },
                })
            }

            None => TweetJson::Tweet(Tweet {
                text: self.text.clone(),
            }),
        };

        send_tweet(token, serde_json::to_value(&json).unwrap())
            .await
            .context(TwitterSnafu)
    }
}

//

#[derive(Clone, Debug, new)]
pub struct RssTask {
    pub id: uuid::Uuid,
    pub schedule: Schedule,
    pub user_id: String,
    pub url: String,
    pub random: bool,
    pub last_pub_date: Option<OffsetDateTime>,
    pub template: Option<String>,
}

impl RssTask {
    async fn run_task<F, Fut>(task: Self, send_tweet: F)
    where
        F: FnOnce(Token, serde_json::Value) -> Fut,
        Fut: Future<Output = Result<String, crate::twitter::Error>>,
    {
        tracing::info!("Tyring RSS post from {}", task.url);

        match task.exec_tweet(send_tweet).await {
            Ok(_) => tracing::info!("RSS post 成功"),
            Err(err) => tracing::info!("RSS post 失敗 {}", err),
        }
    }

    async fn exec_tweet<F, Fut>(&self, send_tweet: F) -> Result<String, Error>
    where
        F: FnOnce(Token, serde_json::Value) -> Fut,
        Fut: Future<Output = Result<String, crate::twitter::Error>>,
    {
        let mut feed = RssFeed::new(&self.url).await?;

        let len = feed.items.len();

        feed.items.sort_by(|a, b| b.pub_date.cmp(&a.pub_date));

        let rss_item = if self.random {
            let index = random!(1, len);
            feed.items.get(index - 1)
        } else {
            match feed.items.first() {
                Some(post) => match self.last_pub_date {
                    Some(last_pub_date) => {
                        if post.pub_date > last_pub_date {
                            Some(post)
                        } else {
                            None
                        }
                    }
                    None => Some(post),
                },
                None => None,
            }
        };

        let rss_item = rss_item.whatever_context(
            "スケージュールされていますが、ツイート対象のメッセージがありません",
        )?;

        let message = rss_item.to_message(self.template.clone());

        tracing::info!("これから次のメッセージをツイートします");
        tracing::info!("{}", message);

        let token = crate::gq::load_session::load_session(
            self.user_id.clone(),
            crate::state::oauth_client(),
        )
        .await
        .context(crate::error::GraphqlSnafu)?;

        let json = TweetJson::Tweet(Tweet { text: message });

        let resp = send_tweet(token, serde_json::to_value(&json).unwrap())
            .await
            .context(TwitterSnafu)?;

        if crate::gq::update_last_pub_date_task_rss::exec(self.id, feed.pub_date)
            .await
            .is_err()
        {
            tracing::warn!("Ignoring error on updating last_pub_date");
        }

        Ok(resp)
    }

    pub fn to_schedule2(task: Self, scheduler: &mut clokwerk::AsyncScheduler) {
        use clokwerk::Job;

        let jobs = if task.random {
            task.schedule.to_asyncjob(scheduler)
        } else {
            // 一定時間ごとにRSSフィードをチェックするようにスケジュールする
            // Basicプランでは4時間おき
            // Premiumプランでは1時間おき？
            let tweet_at = format_tweet_at(task.schedule.tweet_at.clone());

            scheduler
                .every(clokwerk::Interval::Days(1))
                .at(&tweet_at)
                .and_every(clokwerk::Interval::Hours(4)) // set the interval to 4 hours
        };
        let task_cloned: RssTask = task.clone();
        jobs.run(move || Self::run_task(task_cloned.clone(), crate::twitter::send_tweet_impl));
    }
}

fn format_tweet_at(time: time::Time) -> String {
    let format = time::format_description::parse("[hour]:[minute]:[second]").expect(
        "ここでエラーになるはずはありません。時間フォーマットのテンプレートに誤りがあるので見直してください。",
        );

    time.format(&format).expect(
        "time::Timeで表現されるた時刻のフォーマット時にエラーが発生したが本来はありえない。",
    )
}

#[derive(Clone, Debug, new)]
pub struct Schedule {
    pub tweet_at: time::Time,
    pub sun: bool,
    pub mon: bool,
    pub tue: bool,
    pub wed: bool,
    pub thu: bool,
    pub fri: bool,
    pub sat: bool,
}

impl Schedule {
    pub fn to_asyncjob<'a>(
        &self,
        scheduler: &'a mut clokwerk::AsyncScheduler,
    ) -> &'a mut clokwerk::AsyncJob {
        use clokwerk::Job;

        let days = [
            self.clone().sun,
            self.clone().mon,
            self.clone().tue,
            self.clone().wed,
            self.clone().thu,
            self.clone().fri,
            self.clone().sat,
        ];

        let tweet_at = format_tweet_at(self.clone().tweet_at);

        scheduler
            .every(clokwerk::Interval::Sunday)
            .at(&tweet_at)
            .count(days[0] as usize)
            .and_every(clokwerk::Interval::Monday)
            .at(&tweet_at)
            .count(days[1] as usize)
            .and_every(clokwerk::Interval::Tuesday)
            .at(&tweet_at)
            .count(days[2] as usize)
            .and_every(clokwerk::Interval::Wednesday)
            .at(&tweet_at)
            .count(days[3] as usize)
            .and_every(clokwerk::Interval::Thursday)
            .at(&tweet_at)
            .count(days[4] as usize)
            .and_every(clokwerk::Interval::Friday)
            .at(&tweet_at)
            .count(days[5] as usize)
            .and_every(clokwerk::Interval::Saturday)
            .at(&tweet_at)
            .count(days[6] as usize)
    }
}

/// Enabled Task
#[derive(Clone, Debug, new)]
pub struct EnabledTask {
    pub schedule: Schedule,
    pub user_id: String,
    // pub tag_id: Option<uuid::Uuid>,
    pub messages: Vec<Message>,
    pub random: bool,
}

impl EnabledTask {
    async fn run_task(mut task: Self) {
        tracing::info!("TWEEET ");

        let len = task.messages.len();
        if len > 0 {
            task.messages
                .sort_by(|a, b: &Message| b.created_at.cmp(&a.created_at));

            let message = if task.random {
                let index = random!(1, len);

                task.messages.get(index - 1)
            } else {
                task.messages.first()
            };

            if let Some(message) = message {
                tracing::info!("これから次のメッセージをツイートします");
                tracing::info!("{:?}", message);

                let client = crate::state::oauth_client();
                match crate::gq::load_session::load_session(task.user_id.clone(), client).await {
                    Ok(token) => {
                        match message.tweet(token, crate::twitter::send_tweet_impl).await {
                            Ok(_) => tracing::info!("ツイート成功！"),
                            Err(err) => tracing::error!("Tweetの実行に失敗しました: {:?}", err),
                        }
                    }
                    Err(err) => {
                        tracing::error!(
                            "セッション情報の読み込み時にエラーが発生しました: {:?}",
                            err
                        )
                    }
                }
            } else {
                tracing::warn!("スケージュールされていますが、メッセージが登録されていません。")
            }
        } else {
            tracing::warn!("スケージュールされていますが、メッセージが登録されていません。")
        }
    }

    pub fn to_schedule2(task: Self, scheduler: &mut clokwerk::AsyncScheduler) {
        let jobs = task.schedule.to_asyncjob(scheduler);

        let task_cloned: EnabledTask = task.clone();
        jobs.run(move || Self::run_task(task_cloned.clone()));
    }
}

#[derive(Serialize, Deserialize, Debug, new)]
#[serde(rename_all = "camelCase")]
pub struct Media {
    pub id: uuid::Uuid,
    pub user_id: String,
    pub thumbnail: String,
    pub uploaded_at: OffsetDateTime,
}

#[derive(Deserialize, Serialize, Debug, Clone)]
pub struct RssFeed {
    title: String,
    link: String,
    pub_date: OffsetDateTime,
    items: Vec<RssItem>,
}

#[derive(Deserialize, Serialize, Debug, new, Clone)]
pub struct RssItem {
    title: String,
    link: String,
    pub_date: OffsetDateTime,
}

impl RssItem {
    fn to_message(&self, template: Option<String>) -> String {
        match template {
            Some(template) => template
                .replace("{title}", &self.title)
                .replace("{pub_date}", &self.pub_date.to_string())
                .replace("{url}", &self.link)
                .replace("\\n", "\n"),

            None => format!("{}\n\n{}", self.title, self.link),
        }
    }
}

impl RssFeed {
    async fn new(url: &str) -> Result<Self, Error> {
        use rss::Channel;

        let client = reqwest::Client::new();
        let resp = client
            .get(url)
            .header(
                "User-Agent",
                "Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv 11.0) like Gecko",
            )
            .send()
            .await
            .whatever_context("Failed to get RSS feeds")?;

        let bytes = resp
            .bytes()
            .await
            .whatever_context("Failed to read RSS response as bytes")?;
        let channel = Channel::read_from(&bytes[..])
            .whatever_context("Failed to read bytes as RSS channel")?;

        let pub_date = time::OffsetDateTime::parse(
            &channel.pub_date.unwrap(),
            &time::format_description::well_known::Rfc2822,
        )
        .whatever_context("Failed parse pub_date")?;

        let items = channel
            .items
            .into_iter()
            .map(|item| {
                let pub_date = time::OffsetDateTime::parse(
                    &item.pub_date.unwrap(),
                    &time::format_description::well_known::Rfc2822,
                )
                .unwrap();
                RssItem::new(item.title.unwrap(), item.link.unwrap(), pub_date)
            })
            .collect();

        Ok(Self {
            title: channel.title,
            link: channel.link,
            pub_date,
            items,
        })
    }
}

#[tokio::test]
async fn test_get_rss_feed() -> Result<(), Error> {
    let url = "https://shichimaru.com/rss/blog";
    let feed = RssFeed::new(url).await?;

    assert!(feed.items.len() > 0);
    Ok(())
}
