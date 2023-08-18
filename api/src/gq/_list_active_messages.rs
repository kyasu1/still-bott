/*
query ListActiveMessages($user_id: String!, $tag_id: uuid!) {
  user(where: {id: {_eq: $user_id}, active: {_eq: true}}) {
    messages(where: {tag_id: {_eq: $tag_id}}) {
      media_id
      priority
      text
      id
    }
  }
}
*/
#[cynic::schema_for_derives(file = r#"schema.graphql"#, module = "schema")]
mod queries {
    use crate::gq::common::*;

    #[derive(cynic::QueryVariables, Debug)]
    pub struct ListActiveMessagesVariables {
        pub tag_id: Uuid,
        pub user_id: String,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "query_root", variables = "ListActiveMessagesVariables")]
    pub struct ListActiveMessages {
        #[arguments(where: { active: { _eq: true }, id: { _eq: $user_id } })]
        pub user: Vec<user>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(variables = "ListActiveMessagesVariables")]
    pub struct user {
        #[arguments(where: { tag_id: { _eq: $tag_id } })]
        pub messages: Vec<message>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    pub struct message {
        #[cynic(rename = "media_id")]
        pub media_id: Option<Uuid>,
        pub priority: i32,
        pub text: String,
        pub id: Uuid,
    }
}

pub async fn load_active_messages(
    user_id: String,
    tag_id: uuid::Uuid,
) -> Result<Option<crate::model::Message>, String> {
    use cynic::QueryBuilder;

    let vars = queries::ListActiveMessagesVariables {
        tag_id: super::common::Uuid(tag_id),
        user_id: user_id.clone(),
    };
    let operation = queries::ListActiveMessages::build(vars);

    match super::common::run_graphql(operation).await {
        Ok(resp) => match resp.data {
            Some(data) => match data.user.first() {
                Some(user) => match user.messages.first() {
                    Some(message) => Ok(Some(crate::model::Message::new(
                        message.id.0,
                        user_id.clone(),
                        message.text.clone(),
                        message.media_id.clone().map(|media_id| media_id.0),
                        message.priority,
                    ))),
                    None => Ok(None),
                },

                None => Ok(None),
            },
            None => Ok(None),
        },

        Err(err) => {
            tracing::debug!("error: {:?}", err);
            Err("ERR".to_string())
        }
    }
}
