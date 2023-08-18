/*
query ListActiveTasks {
  user(where: {active: {_eq: true}}) {
    id
    tasks_fixed_time(where: {enabled: {_eq: true}}) {
      fri
      id
      mon
      random
      sat
      sun
      thu
      tue
      tweet_at
      wed
      tag {
        messages {
          priority
          media_id
          text
          id
          created_at
          updated_at
        }
      }
    }
    tasks_rss(where: {enabled: {_eq: true}}) {
      fri
      id
      mon
      random
      sat
      sun
      thu
      tue
      tweet_at
      wed
      template
      url
      last_pub_date
    }
  }
}
*/

#[cynic::schema_for_derives(file = r#"schema.graphql"#, module = "schema")]
mod queries {
    use crate::gq::common::scalars::*;
    use crate::gq::common::schema;

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "query_root")]
    pub struct ListActiveTasks {
        #[arguments(where: { active: { _eq: true } })]
        pub user: Vec<user>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[allow(non_camel_case_types)]
    pub struct user {
        pub id: String,
        #[arguments(where: { enabled: { _eq: true } })]
        #[cynic(rename = "tasks_fixed_time")]
        pub tasks_fixed_time: Vec<task_fixed_time>,

        #[arguments(where: { enabled: { _eq: true } })]
        #[cynic(rename = "tasks_rss")]
        pub tasks_rss: Vec<TaskRss>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[allow(non_camel_case_types)]
    pub struct task_fixed_time {
        pub fri: bool,
        pub id: Uuid,
        pub mon: bool,
        pub random: bool,
        pub sat: bool,
        pub sun: bool,
        pub thu: bool,
        pub tue: bool,
        #[cynic(rename = "tweet_at")]
        pub tweet_at: Time,
        pub wed: bool,
        pub tag: Option<tag>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[allow(non_camel_case_types)]
    pub struct tag {
        pub messages: Vec<message>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[allow(non_camel_case_types)]
    pub struct message {
        pub priority: i32,
        #[cynic(rename = "media_id")]
        pub media_id: Option<Uuid>,
        pub text: String,
        pub id: Uuid,
        #[cynic(rename = "created_at")]
        pub created_at: Timestamptz,
        #[cynic(rename = "updated_at")]
        pub updated_at: Timestamptz,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "task_rss")]
    pub struct TaskRss {
        pub fri: bool,
        pub id: Uuid,
        pub mon: bool,
        pub random: bool,
        pub sat: bool,
        pub sun: bool,
        pub thu: bool,
        pub tue: bool,
        #[cynic(rename = "tweet_at")]
        pub tweet_at: Time,
        pub wed: bool,
        pub template: Option<String>,
        pub url: String,
        #[cynic(rename = "last_pub_date")]
        pub last_pub_date: Option<Timestamptz>,
    }
}

use super::error::{build_errors, HasuraError, NetworkSnafu};

use snafu::prelude::*;

use crate::model::{ActiveUser, EnabledTask, Message, RssTask, Schedule};

pub async fn list_active_tasks() -> Result<Vec<crate::model::ActiveUser>, HasuraError> {
    use cynic::QueryBuilder;

    let operation = queries::ListActiveTasks::build(());

    let resp = super::common::run_graphql(operation)
        .await
        .context(NetworkSnafu)?;

    resp.data
        .ok_or_else(|| build_errors(resp.errors))
        .map(|data| {
            data.user
                .iter()
                .map(|user| {
                    let tasks = user
                        .tasks_fixed_time
                        .iter()
                        // .filter(|task| task.tag.is_some())
                        .map(|task| {
                            let messages = match &task.tag {
                                Some(tag) => tag
                                    .messages
                                    .iter()
                                    .map(|message| {
                                        Message::new(
                                            message.id.0,
                                            user.id.clone(),
                                            message.text.clone(),
                                            message.media_id.clone().map(|media_id| media_id.0),
                                            message.priority,
                                            message.created_at.clone().into(),
                                            message.updated_at.clone().into(),
                                        )
                                    })
                                    .collect(),
                                None => vec![],
                            };

                            let format =
                                time::macros::format_description!("[hour]:[minute]:[second]");

                            let schedule = Schedule::new(
                                time::Time::parse(&task.tweet_at.0, format).unwrap(),
                                task.sun,
                                task.mon,
                                task.tue,
                                task.wed,
                                task.thu,
                                task.fri,
                                task.sat,
                            );
                            EnabledTask::new(schedule, user.id.clone(), messages, task.random)
                        })
                        .collect();

                    let tasks_rss = user
                        .tasks_rss
                        .iter()
                        .map(|task| {
                            let format =
                                time::macros::format_description!("[hour]:[minute]:[second]");

                            let schedule = Schedule::new(
                                time::Time::parse(&task.tweet_at.0, format).unwrap(),
                                task.sun,
                                task.mon,
                                task.tue,
                                task.wed,
                                task.thu,
                                task.fri,
                                task.sat,
                            );

                            RssTask::new(
                                task.id.0,
                                schedule,
                                user.id.clone(),
                                task.url.clone(),
                                task.random,
                                task.last_pub_date.clone().map(|d| d.into()),
                                task.template.clone(),
                            )
                        })
                        .collect();

                    ActiveUser::new(user.id.clone(), tasks, tasks_rss)
                })
                .collect()
        })
    // let users = super::common::run_graphql(operation)
    //     .await
    //     .map_err(GraphqlError::NetworkError)?
    //     .data
    //     .ok_or(GraphqlError::DataNotFound)?
    //     .user
    //     .iter()
    //     .map(|user| {
    //         let tasks = user
    //             .tasks_fixed_time
    //             .iter()
    //             // .filter(|task| task.tag.is_some())
    //             .map(|task| {
    //                 let messages = match &task.tag {
    //                     Some(tag) => tag
    //                         .messages
    //                         .iter()
    //                         .map(|message| {
    //                             Message::new(
    //                                 message.id.0,
    //                                 user.id.clone(),
    //                                 message.text.clone(),
    //                                 message.media_id.clone().map(|media_id| media_id.0),
    //                                 message.priority,
    //                                 message.created_at.clone().into(),
    //                                 message.updated_at.clone().into(),
    //                             )
    //                         })
    //                         .collect(),
    //                     None => vec![],
    //                 };

    //                 let format = time::macros::format_description!("[hour]:[minute]:[second]");

    //                 let schedule = Schedule::new(
    //                     time::Time::parse(&task.tweet_at.0, format).unwrap(),
    //                     task.sun,
    //                     task.mon,
    //                     task.tue,
    //                     task.wed,
    //                     task.thu,
    //                     task.fri,
    //                     task.sat,
    //                 );
    //                 EnabledTask::new(schedule, user.id.clone(), messages, task.random)
    //             })
    //             .collect();

    //         let tasks_rss = user
    //             .tasks_rss
    //             .iter()
    //             .map(|task| {
    //                 let format = time::macros::format_description!("[hour]:[minute]:[second]");

    //                 let schedule = Schedule::new(
    //                     time::Time::parse(&task.tweet_at.0, format).unwrap(),
    //                     task.sun,
    //                     task.mon,
    //                     task.tue,
    //                     task.wed,
    //                     task.thu,
    //                     task.fri,
    //                     task.sat,
    //                 );

    //                 RssTask::new(
    //                     task.id.0,
    //                     schedule,
    //                     user.id.clone(),
    //                     task.url.clone(),
    //                     task.random,
    //                     task.last_pub_date.clone().map(|d| d.into()),
    //                     task.template.clone(),
    //                 )
    //             })
    //             .collect();

    //         ActiveUser::new(user.id.clone(), tasks, tasks_rss)
    //     })
    //     .collect();

    // Ok(users)
}
