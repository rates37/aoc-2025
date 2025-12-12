let read_filecontents filename =
  let f = open_in filename in
  let data = really_input_string f (in_channel_length f) in
  close_in f;
  String.trim data

let get_last lst = List.hd (List.rev lst)
let get_all_but_last lst = List.rev @@ List.tl @@ List.rev lst

let count_char c s =
  String.fold_left (fun acc v -> if v = c then acc + 1 else acc) 0 s

let parse_dimensions s =
  match String.split_on_char 'x' s |> List.map int_of_string with
  | [ w; h ] -> (w, h)
  | _ -> failwith "ruh roh"

let parse_counts s = s |> Str.split (Str.regexp " ") |> List.map int_of_string

let req_area counts hash_counts =
  List.fold_left2 (fun acc a1 a2 -> acc + (a1 * a2)) 0 counts hash_counts

let process_region_line hash_counts count_ref line =
  match String.split_on_char ':' line with
  | [ dims; counts_str ] ->
      let dims = String.trim dims in
      let counts_str = String.trim counts_str in

      let w, h = parse_dimensions dims in
      let counts = parse_counts counts_str in
      let required_area = req_area counts hash_counts in

      if required_area <= w * h then
        let sum_counts = List.fold_left ( + ) 0 counts in
        if sum_counts <= w / 3 * (h / 3) then incr count_ref
  | _ -> failwith "ooooof (input malformed)"

let part1 filename =
  (* Read input file: *)
  let content = read_filecontents filename in

  (* Separate shapes vs regions *)
  let blocks = Str.split (Str.regexp "\n\n") content in
  let shapes = get_all_but_last blocks in
  let regions = Str.split (Str.regexp "\n") @@ get_last blocks in

  (* Count number of hashes per shape: *)
  let hash_counts = List.map (count_char '#') shapes in

  (* Count number of valid regions: *)
  let count = ref 0 in
  List.iter (process_region_line hash_counts count) regions;
  !count

let () =
  if Array.length Sys.argv < 2 then (
    Printf.printf "Provide input txt filename as only argument";
    exit 1);
  Printf.printf "%d\n" @@ part1 Sys.argv.(1)
