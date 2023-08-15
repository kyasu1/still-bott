use crate::config::CONFIG;
use crate::mpsc;
use async_sqlx_session::PostgresSessionStore;
use axum::extract::FromRef;
use axum_extra::extract::cookie::Key;
use oauth2::{basic::BasicClient, AuthUrl, ClientId, ClientSecret, RedirectUrl, TokenUrl};

#[derive(Clone)]
pub struct AppState {
    pub store: PostgresSessionStore,
    pub oauth_client: BasicClient,
    pub key: Key,
    pub actor_handle: mpsc::ActorHandle,
}

impl FromRef<AppState> for PostgresSessionStore {
    fn from_ref(state: &AppState) -> Self {
        state.store.clone()
    }
}

impl FromRef<AppState> for BasicClient {
    fn from_ref(state: &AppState) -> Self {
        state.oauth_client.clone()
    }
}

impl FromRef<AppState> for Key {
    fn from_ref(state: &AppState) -> Self {
        state.key.clone()
    }
}

impl FromRef<AppState> for mpsc::ActorHandle {
    fn from_ref(state: &AppState) -> Self {
        state.actor_handle.clone()
    }
}

pub fn oauth_client() -> BasicClient {
    let client_id = CONFIG.twitter_client_id.clone();
    let client_secret = CONFIG.twitter_client_secret.clone();
    let redirect_url = format!("{}/auth/authorized", CONFIG.backend_endpoint);
    let auth_url = CONFIG.twitter_auth_url.clone();
    let token_url = CONFIG.twitter_token_url.clone();

    BasicClient::new(
        ClientId::new(client_id),
        Some(ClientSecret::new(client_secret)),
        AuthUrl::new(auth_url).unwrap(),
        Some(TokenUrl::new(token_url).unwrap()),
    )
    .set_redirect_uri(RedirectUrl::new(redirect_url).unwrap())
}

pub async fn setup_state(sender: tokio::sync::mpsc::Sender<mpsc::ActorMessage>) -> AppState {
    let store = PostgresSessionStore::new(&CONFIG.postgres_endpoint)
        .await
        .expect("Failed to connect Postgres");
    store
        .migrate()
        .await
        .expect("Failed to initialize async_session table");

    let oauth_client = oauth_client();
    let key = Key::generate();

    let actor_handle = mpsc::ActorHandle { sender };

    AppState {
        store,
        oauth_client,
        key,
        actor_handle,
    }
}
