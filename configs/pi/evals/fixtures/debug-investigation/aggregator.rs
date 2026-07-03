use std::collections::HashMap;

#[derive(Default, Debug)]
struct PartialCall {
    name: String,
    args: String,
}

fn main() {
    let mut pending: HashMap<String, PartialCall> = HashMap::new();

    pending.entry("call_123".into()).or_default().name = "lookup".into();
    pending.entry("item_abc".into()).or_default().args.push_str("{\"query\":\"tea\"}");

    let done_id = "call_123";
    let partial = pending.entry(done_id.into()).or_default();
    println!("args: {:?}, partial: {:?}", partial.args, partial);
}
