use once_cell::sync::Lazy;
use serde::Deserialize;

pub static CONFIG: Lazy<Config> = Lazy::new(|| Config::new().expect("Failed to setup config"));

#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    pub log_level: String,

    pub twitter_client_id: String,
    pub twitter_client_secret: String,

    pub backend_endpoint: String,
    pub server_port: u16,

    pub hasura_graphql_admin_secret: String,
    pub hasura_action_secret: String,

    pub hasura_graphql_endpoint: String,
    pub postgres_endpoint: String,

    pub minio_endpoint: String,

    pub smtp_username: String,
    pub smtp_password: String,

    hasura_graphql_jwt_secret: String,

    // for oauth_1
    api_key: String,
    api_secret_key: String,
    access_token: String,
    access_token_secret: String,
}

impl Config {
    pub fn new() -> Result<Self, envy::Error> {
        envy::from_env::<Config>()
    }

    pub fn jwt_secret(&self) -> String {
        let jwt_secret: JwtSecret = serde_json::from_str(&self.hasura_graphql_jwt_secret)
            .expect("Failed to parse JWT Secret");
        jwt_secret.key
    }

    pub fn oauth_1_token(&self) -> oauth::Token {
        oauth::Token::from_parts(
            self.api_key.clone(),
            self.api_secret_key.clone(),
            self.access_token.clone(),
            self.access_token_secret.clone(),
        )
    }
}

#[derive(Deserialize)]
struct JwtSecret {
    #[serde(rename = "type")]
    type_: String,
    key: String,
}
