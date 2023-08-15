use std::collections::HashMap;

// https://desilva.io/posts/spawn-tasks-and-talk-to-them-via-a-channel-with-axum
// https://iq.opengenus.org/mpsc-shared-state-concurrency-rust/
// use crate::error::Error;
use crate::scheduler;
use clokwerk::AsyncScheduler;
use tokio::sync::mpsc;

pub struct Actor {
    workers: std::collections::HashMap<String, Option<tokio::task::JoinHandle<AsyncScheduler>>>,
    receiver: mpsc::Receiver<ActorMessage>,
}

#[derive(Debug)]
pub enum ActorMessage {
    StartScheduler,
    RestartUserSchedule { user_id: String },
}

impl std::fmt::Display for ActorMessage {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ActorMessage::StartScheduler => {
                write!(f, "ActorMessage::StartScheduler")
            }
            ActorMessage::RestartUserSchedule { user_id } => {
                write!(
                    f,
                    "ActorMessage::RestartUserSchedule: {{ user_id: {} }}",
                    user_id
                )
            }
        }
    }
}

impl Actor {
    pub fn new(receiver: mpsc::Receiver<ActorMessage>) -> Self {
        Actor {
            workers: std::collections::HashMap::new(),
            receiver,
        }
    }

    // async fn handle_message(&mut self, msg: ActorMessage) -> Result<(), Error> {
    //     match msg {
    //         ActorMessage::StartScheduler => {
    //             self.start_scheduler().await?;

    //             Ok(())
    //         }

    //         ActorMessage::RestartUserSchedule { user_id } => {
    //             tracing::info!("Restarting Schedule...");
    //             if let Some(worker) = self.workers.get(&user_id.clone()) {
    //                 if let Some(worker) = worker {
    //                     tracing::info!("Stopping existing schedule for the user: {}", user_id);
    //                     worker.abort();
    //                 }
    //             }
    //             match scheduler::start_task_for_user(user_id.clone()).await {
    //                 Ok(handle) => {
    //                     tracing::info!("Restared schedule for the user: {}", user_id);
    //                     self.workers.insert(user_id, handle).unwrap();
    //                     Ok(())
    //                 }
    //                 Err(err) => {
    //                     tracing::error!("Error when starting scheduler: {}", err);
    //                     Ok(())
    //                 }
    //             }
    //         }
    //     }
    // }

    // async fn start_scheduler(&mut self) -> Result<(), Error> {
    //     tracing::info!("Starting scheduler...");
    //     let workers = scheduler::start_scheduler().await?;
    //     self.workers = workers;
    //     tracing::info!("Schedule started...");
    //     Ok(())
    // }

    // pub async fn run(&mut self) -> Result<(), Error> {
    //     self.start_scheduler().await?;

    //     while let Some(msg) = self.receiver.recv().await {
    //         tracing::info!("Receiver: {}", &msg);
    //         self.handle_message(msg).await?;
    //     }

    //     Ok(())
    // }

    async fn handle_message(&mut self, msg: ActorMessage) -> () {
        match msg {
            ActorMessage::StartScheduler => {
                self.start_scheduler().await;
            }

            ActorMessage::RestartUserSchedule { user_id } => {
                tracing::info!("Restarting Schedule...");
                if let Some(worker) = self.workers.get(&user_id.clone()) {
                    if let Some(worker) = worker {
                        tracing::info!("Stopping existing schedule for the user: {}", user_id);
                        worker.abort();
                    }
                }
                match scheduler::start_task_for_user(user_id.clone()).await {
                    Ok(handle) => {
                        tracing::info!("Restared schedule for the user: {}", user_id);
                        self.workers.insert(user_id, handle).unwrap();
                    }
                    Err(err) => {
                        tracing::error!("Error when starting scheduler: {}", err);
                    }
                }
            }
        }
    }
    async fn start_scheduler(&mut self) -> () {
        tracing::info!("Starting scheduler...");
        match scheduler::start_scheduler().await {
            Ok(workers) => self.workers = workers,
            Err(_) => self.workers = HashMap::new(),
        }
        tracing::info!("Schedule started...");
    }

    pub async fn run(&mut self) {
        self.start_scheduler().await;

        while let Some(msg) = self.receiver.recv().await {
            tracing::info!("Receiver: {}", &msg);
            self.handle_message(msg).await;
        }
    }
}

#[derive(Clone)]
pub struct ActorHandle {
    pub sender: mpsc::Sender<ActorMessage>,
}

impl ActorHandle {
    pub async fn start_scheduler(&self) {
        let msg = ActorMessage::StartScheduler;
        if (self.sender.send(msg).await).is_err() {
            tracing::warn!("receiver dropped");
            assert!(self.sender.is_closed());
        }
    }
    pub async fn restart_task_for_user(&self, user_id: String) -> bool {
        let msg = ActorMessage::RestartUserSchedule { user_id };
        if (self.sender.send(msg).await).is_err() {
            tracing::warn!("receiver dropped");
            assert!(self.sender.is_closed());
            false
        } else {
            true
        }
    }
}
