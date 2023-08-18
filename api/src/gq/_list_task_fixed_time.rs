/*
query ListTaskFixedTime {
  task_fixed_time(where: {enabled: {_eq: true}}) {
    tweet_at
    fri
    mon
    random
    sat
    sun
    thu
    tue
    user_id
    wed
    tag_id
  }
}
*/
#[cynic::schema_for_derives(file = r#"schema.graphql"#, module = "schema")]
mod queries {
    use crate::gq::common::*;

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "query_root")]
    pub struct ListTaskFixedTime {
        #[arguments(where: { enabled: { _eq: true } })]
        #[cynic(rename = "task_fixed_time")]
        pub task_fixed_time: Vec<task_fixed_time>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    pub struct task_fixed_time {
        #[cynic(rename = "tweet_at")]
        pub tweet_at: Time,
        pub fri: bool,
        pub mon: bool,
        pub random: bool,
        pub sat: bool,
        pub sun: bool,
        pub thu: bool,
        pub tue: bool,
        #[cynic(rename = "user_id")]
        pub user_id: String,
        pub wed: bool,
        #[cynic(rename = "tag_id")]
        pub tag_id: Option<Uuid>,
    }
}

pub async fn load_tasks() -> Result<Vec<crate::model::EnabledTask>, String> {
    use cynic::QueryBuilder;

    let format = time::macros::format_description!("[hour]:[minute]:[second]");

    let operation = queries::ListTaskFixedTime::build(());

    match super::common::run_graphql(operation).await {
        Ok(resp) => match resp.data {
            Some(data) => Ok(data
                .task_fixed_time
                .into_iter()
                .map(|e| crate::model::EnabledTask {
                    tweet_at: time::Time::parse(&e.tweet_at.0, format).unwrap(),
                    sun: e.sun,
                    mon: e.mon,
                    tue: e.tue,
                    wed: e.wed,
                    thu: e.thu,
                    fri: e.fri,
                    sat: e.sat,
                    user_id: e.user_id,
                    random: e.random,
                    tag_id: e.tag_id.map(|uuid| uuid.0),
                })
                .collect::<Vec<crate::model::EnabledTask>>()),
            None => {
                tracing::warn!("No tasks found so we are skipping..");
                Ok(vec![])
            }
        },
        Err(err) => {
            tracing::debug!("error: {:?}", err);
            Err("ERR".to_string())
        }
    }
}
