extern crate tokio;
use serde::{Deserialize, Serialize};
#[allow(unused_imports)]
#[cfg(feature = "tokio-runtime")]
pub use tokio::{main, test};
mod bib;
use bib::*;
use serde_json::Value;

use std::convert::TryInto;
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

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let bbl = get_bibliography();
    println!("Start server");
    let mut socket = zeromq::RepSocket::new();
    socket
        .bind("ipc:///home/andrei/.local/run/rust-extras.ipc")
        .await?;

    loop {
        let repl: String = socket.recv().await?.try_into()?;

        dbg!(&repl);
        let req: Req = serde_json::from_str(&repl).unwrap();
        match req.req_type {
            ReqType::BibTeX => match req.payload {
                Value::String(x) => {
                    let bibitem = get_bibitem(&x, &bbl).unwrap();

                    let reply = serde_json::to_string(&bibitem).unwrap();
                    socket.send(reply.into()).await?
                }
                _ => panic!("unexpected request of BibTeX"),
            },
        }
    }
}
