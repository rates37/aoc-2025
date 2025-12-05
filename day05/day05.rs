use std::env;
use std::fs;
use std::io;

fn merge_ranges(mut ranges: Vec<(i64, i64)>) -> Vec<(i64, i64)> {
    ranges.sort_by_key(|rang| (rang.0, rang.1));

    let mut merged: Vec<(i64, i64)> = Vec::new();

    for (start, end) in ranges {
        if let Some((_, prev_end)) = merged.last_mut() {
            if start <= (*prev_end) + 1 {
                *prev_end = (*prev_end).max(end);
                continue;
            }
        }
        merged.push((start, end))
    }

    merged
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();

    if args.len() != 2 {
        println!("Provide input filename as only input");
        return Ok(());
    }

    // read in input:
    let contents = fs::read_to_string(args[1].clone())?;

    let parts: Vec<&str> = contents.split("\n\n").collect();

    let range_vec: Vec<_> = parts
        .get(0)
        .unwrap_or(&"")
        .lines()
        .map(String::from)
        .map(|s| {
            let (a, b) = s.split_once('-').unwrap(); // lazy assuming input is correctly formatted
            (a.parse::<i64>().unwrap(), b.parse::<i64>().unwrap())
        })
        .collect();
    let id_vec: Vec<_> = parts
        .get(1)
        .unwrap_or(&"")
        .lines()
        .map(String::from)
        .map(|s| s.parse::<i64>().unwrap_or(-1))
        .collect();

    let mut count = 0;
    for n in id_vec {
        if n == -1 {
            continue;
        }
        // check if num in any of the ranges:
        for (a, b) in &range_vec {
            if *a <= n && n <= *b {
                count += 1;
                break;
            }
        }
    }
    println!("Part 1: {}", count);

    let mut valid_ids = 0;
    let merged_ranges = merge_ranges(range_vec);

    for (a, b) in &merged_ranges {
        valid_ids += *b - *a + 1;
    }
    println!("Part 2: {}", valid_ids);

    Ok(())
}
