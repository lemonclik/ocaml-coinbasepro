open Sexplib.Std

module Ezjsonm_encoding = struct
  include Json_encoding.Make(Json_repr.Ezjsonm)

  let destruct_safe encoding value =
    try destruct encoding value with exn ->
      Format.eprintf "%a@."
        (Json_encoding.print_error ?print_unknown:None) exn ;
      raise exn
end

module Ptime = struct
  include Ptime

  let t_of_sexp sexp =
    let sexp_str = string_of_sexp sexp in
    match of_rfc3339 sexp_str with
    | Ok (t, _, _) -> t
    | _ -> invalid_arg "Ptime.t_of_sexp"

  let sexp_of_t t =
    sexp_of_string (to_rfc3339 t)

  let encoding =
    let open Json_encoding in
    conv
      (fun t -> Ptime.to_rfc3339 t)
      (fun ts -> match Ptime.of_rfc3339 ts with
         | Error _ -> invalid_arg "Ptime.encoding"
         | Ok (t, _, _) -> t)
      string
end

module Uuidm = struct
  include Uuidm

  let t_of_sexp sexp =
    let sexp_str = string_of_sexp sexp in
    match of_string sexp_str with
    | None -> invalid_arg "Uuidm.t_of_sexp"
    | Some u -> u

  let sexp_of_t t =
    sexp_of_string (to_string t)

  let encoding =
    let open Json_encoding in
    conv
      (fun u -> to_string u)
      (fun s -> match of_string s with
         | None -> invalid_arg "Uuidm.encoding"
         | Some u -> u)
      string
end

let strfloat =
  let open Json_encoding in
  union [
    case float (fun s -> Some s) (fun s -> s) ;
    case string (fun s -> Some (string_of_float s)) float_of_string ;
  ]
