use biblatex::{Bibliography, Entry, ParseError, Person};
use itertools::intersperse;
use serde::Serialize;
use serde_json::Value;
use std::error::Error;
use std::fmt;
use std::fs;

#[derive(Serialize, Debug)]
pub struct Bib {
    authors: Vec<String>,
    title: String,
    eprint: Option<String>,
    journal: Option<String>,
    year: Option<String>,
    volume: Option<String>,
    pages: Option<String>,
    doi: Option<String>,
}
#[derive(Debug)]
pub struct KeyNotFound {
    key: String,
}
impl fmt::Display for KeyNotFound {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "key >>>{}<<< not found", self.key)
    }
}
impl Error for KeyNotFound {}

pub fn get_bibliography() -> Bibliography {
    let bib_str = fs::read_to_string("/home/andrei/.config/bystrotex.bib").unwrap();
    Bibliography::parse(&bib_str).unwrap()
}

pub fn get_bibitem(id: &str, bbl: &Bibliography) -> Result<Bib, Box<dyn Error>> {
    println!("bibliography size={}", bbl.len());
    let mentry: Option<&Entry> = bbl.iter().filter(|en| en.key == id).next();
    if let Some(entry) = mentry {
        let persons: Vec<Person> = match entry.author() {
            Ok(v) => v,
            _ => panic!("authors retrieval error"),
        };
        let authors: Vec<String> = persons.into_iter().map(|p| format!("{}", p)).collect();
        let titlev = match entry.title() {
            Ok(t) => t
                .iter()
                .map(|sc| sc.v.to_biblatex_string(false))
                .collect::<Vec<String>>(),
            _ => panic!("title retrieval error"),
        };
        let eprint: Option<String> = entry.eprint().ok();
        let journal: Option<String> = entry.journal().ok().map(|x| {
            x.iter()
                .map(|y| y.v.to_biblatex_string(false))
                .collect::<Vec<String>>()
                .join(" ")
                .trim()
                .to_owned()
        });
        let volume: Option<String> = entry.volume().ok().map(|n| match n {
            biblatex::PermissiveType::Typed(m) => m.to_string(),
            biblatex::PermissiveType::Chunks(cs) => cs
                .iter()
                .map(|y| y.v.to_biblatex_string(false))
                .collect::<Vec<String>>()
                .join(""),
        });
        let pages: Option<String> = entry.pages().ok().map(|pp| match pp {
            biblatex::PermissiveType::Typed(vr) => vr
                .iter()
                .map(|r| format!("{}-{}", r.start, r.end))
                .collect::<Vec<String>>()
                .join(",")
                .to_owned(),
            biblatex::PermissiveType::Chunks(cs) => cs
                .iter()
                .map(|c| c.v.to_biblatex_string(false))
                .collect::<Vec<String>>()
                .join(",")
                .to_owned(),
        });
        let year: Option<String> = entry.date().ok().map(|d| match d {
            biblatex::PermissiveType::Typed(dt) => match dt.value {
                biblatex::DateValue::At(x) => x.year.to_string(),
                biblatex::DateValue::After(x) => x.year.to_string(),
                biblatex::DateValue::Before(x) => x.year.to_string(),
                biblatex::DateValue::Between(x, y) => format!("{}-{}", x.year, y.year),
            },
            biblatex::PermissiveType::Chunks(cs) => cs
                .iter()
                .map(|c| c.v.to_biblatex_string(false))
                .collect::<Vec<String>>()
                .join("-")
                .to_owned(),
        });
        let doi: Option<String> = entry.doi().ok();
        let bib = Bib {
            authors,
            title: titlev.join(" ").trim().to_owned(),
            eprint,
            journal,
            year,
            volume,
            pages,
            doi,
        };

        Ok(bib)
        //Ok(serde_json::to_string(&bib).unwrap())
    } else {
        Err(Box::new(KeyNotFound { key: id.to_owned() }))
    }
}
