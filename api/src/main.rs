mod app;
mod config;
mod error;
mod gq;
mod logger;
mod minio;
mod model;
mod mpsc;
mod routes;
mod scheduler;
mod state;
mod twitter;

use std::net::SocketAddr;

#[tokio::main]
async fn main() {
    let (sender, receiver) = tokio::sync::mpsc::channel(8);

    let app_state = crate::state::setup_state(sender).await;

    let app = app::create_app(app_state.clone()).await;
    let addr = SocketAddr::from(([0, 0, 0, 0], config::CONFIG.server_port));

    println!("Server listening on {} rel 02", config::CONFIG.server_port);
    // let backend = async move {
    //     axum::Server::bind(&addr)
    //         .serve(app.into_make_service())
    //         .await
    // };

    let mut actor = mpsc::Actor::new(receiver);
    let feature = tokio::spawn(async move { actor.run().await });

    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();

    // match feature.await {
    //     Ok(Ok(())) => {
    //         let _ = tokio::join!(backend);
    //     }
    //     Ok(Err(e)) => {
    //         tracing::error!("Error {}", e);
    //     }
    //     Err(e) => {
    //         tracing::error!("Join Error {}", e);
    //     }
    // }
}
