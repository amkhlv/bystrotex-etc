extern crate tokio;
use serde::{Deserialize, Serialize};
pub use tokio::{main, test};
mod bib;
use bib::*;
use serde_json::Value;

use homedir::my_home;
use std::convert::TryInto;
use std::path::PathBuf;
use zeromq::*;

#[derive(Serialize, Deserialize)]
enum ReqType {
    BibTeX,
}
#[derive(Serialize, Deserialize)]
struct Req {
    req_type: ReqType,
    payload: Value,
}
#[derive(Serialize)]
enum ErrorReport {
    BibTeXKeyNotFound(String),
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut socket_path: PathBuf = my_home()?.unwrap();
    socket_path.push(".local");
    socket_path.push("run");
    socket_path.push("rust-extras.ipc");
    if socket_path.exists() {
        std::fs::remove_file(&socket_path)?;
    }

    let socket_url = format![
        "ipc://{}",
        socket_path.into_os_string().into_string().unwrap()
    ];

    let bbl = get_bibliography();
    println!("Starting server listening on {}", socket_url);
    let mut socket = zeromq::RepSocket::new();
    socket.bind(&socket_url).await?;

    loop {
        let repl: String = socket.recv().await?.try_into()?;

        dbg!(&repl);
        let req: Req = serde_json::from_str(&repl).unwrap();
        match req.req_type {
            ReqType::BibTeX => match req.payload {
                Value::String(x) => {
                    let bibitemr = get_bibitem(&x, &bbl);

                    if let Ok(bibitem) = bibitemr {
                        let reply = serde_json::to_string(&bibitem).unwrap();
                        socket.send(reply.into()).await?
                    } else {
                        let reply =
                            serde_json::to_string(&ErrorReport::BibTeXKeyNotFound(x)).unwrap();
                        socket.send(reply.into()).await?
                    }
                }
                _ => panic!("unexpected request of BibTeX"),
            },
        }
    }
}
