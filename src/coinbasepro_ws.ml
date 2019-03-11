open Sexplib.Std
open Coinbasepro

type channel =
  | Ticker
  | Level2
  | User
  | Matches
  | Full
[@@deriving sexp]

let channel_encoding =
  let open Json_encoding in
  string_enum [
    "ticker", Ticker ;
    "level2", Level2 ;
    "user", User ;
    "matches", Matches ;
    "full", Full ;
  ]

type channel_full = {
  chan: channel ;
  product_ids : string list ;
} [@@deriving sexp]

let full product_ids =
  { chan = Full ; product_ids }

let channel_full_encoding =
  let open Json_encoding in
  conv
    (fun { chan ; product_ids } -> chan, product_ids)
    (fun (chan, product_ids) -> { chan ; product_ids })
    (obj2
       (req "name" channel_encoding)
       (req "product_ids" (list string)))

let channel_full_encoding =
  let open Json_encoding in
  union [
    case channel_full_encoding
      (fun c -> Some c) (fun c -> c) ;
    case channel_encoding
      (fun { chan ; _ } -> Some chan)
      (fun chan -> { chan ; product_ids = [] })
  ]

let subscription_encoding =
  let open Json_encoding in
  conv
    (fun chans -> ([], chans))
    (fun (_, chans) -> chans)
    (obj2
       (dft "product_ids" (list string) [])
       (req "channels" (list channel_full_encoding)))

type order = {
  ts : Ptime.t ;
  product_id : string ;
  sequence : int64 ;
  order_id : Uuidm.t ;
  client_oid : Uuidm.t option ;
  size : float option ;
  remaining_size : float option ;
  price : float option ;
  side : [`buy|`sell] ;
  ord_type : [`limit|`market] option ;
  ord_status : [`filled|`canceled] option ;
  funds : float option ;
} [@@deriving sexp]

let side_encoding =
  let open Json_encoding in
  string_enum [
    "buy", `buy ;
    "sell", `sell ;
  ]

let ord_type_encoding =
  let open Json_encoding in
  string_enum [
    "limit", `limit ;
    "market", `market ;
  ]

let ord_status_encoding =
  let open Json_encoding in
  string_enum [
    "filled", `filled ;
    "canceled", `canceled ;
  ]

let or_empty_string encoding =
  let open Json_encoding in
  union [
    case (constant "") (fun _ -> None) (fun _ -> None) ;
    case encoding (fun a -> a) (fun a -> Some a) ;
  ]

let order_encoding =
  let open Json_encoding in
  conv
    (fun { ts ; product_id ; sequence ; order_id ; client_oid ;
           size ; remaining_size ; price ; side ; ord_type ; ord_status ; funds} ->
      ((ts, product_id, sequence, order_id, size,
        remaining_size, price, side, ord_type, ord_status), (client_oid, funds)))
    (fun ((ts, product_id, sequence, order_id, size,
           remaining_size, price, side, ord_type, ord_status), (client_oid, funds)) ->
      { ts ; product_id ; sequence ; order_id ; client_oid ;
        size ; remaining_size ; price ; side ; ord_type ; ord_status ; funds })
    (merge_objs
       (obj10
          (req "time" Ptime.encoding)
          (req "product_id" string)
          (req "sequence" int53)
          (req "order_id" Uuidm.encoding)
          (opt "size" strfloat)
          (opt "remaining_size" strfloat)
          (opt "price" strfloat)
          (req "side" side_encoding)
          (opt "order_type" ord_type_encoding)
          (opt "reason" ord_status_encoding))
       (obj2
          (dft "client_oid" (or_empty_string Uuidm.encoding) None)
          (opt "funds" strfloat)))

type ord_match = {
  ts : Ptime.t ;
  product_id : string ;
  sequence : int64 ;
  trade_id : int64 ;
  maker_order_id : Uuidm.t ;
  taker_order_id : Uuidm.t ;
  side : [`buy|`sell] ;
  size : float ;
  price : float ;
} [@@deriving sexp]

let ord_match_encoding =
  let open Json_encoding in
  conv
    (fun { ts ; product_id ; sequence ; trade_id ;
           maker_order_id ; taker_order_id ; side ; size ; price } ->
      (ts, product_id, sequence, trade_id, maker_order_id,
       taker_order_id, side, size, price))
    (fun (ts, product_id, sequence, trade_id, maker_order_id,
          taker_order_id, side, size, price) ->
      { ts ; product_id ; sequence ; trade_id ;
        maker_order_id ; taker_order_id ; side ; size ; price })
    (obj9
       (req "time" Ptime.encoding)
       (req "product_id" string)
       (req "sequence" int53)
       (req "trade_id" int53)
       (req "maker_order_id" Uuidm.encoding)
       (req "taker_order_id" Uuidm.encoding)
       (req "side" side_encoding)
       (req "size" strfloat)
       (req "price" strfloat))

type t =
  | Subscribe of channel_full list
  | Unsubscribe of channel_full list
  | Subscriptions of channel_full list
  | Received of order
  | Done of order
  | Open of order
  | Match of ord_match
[@@deriving sexp]

let pp ppf t =
  Format.fprintf ppf "%a" Sexplib.Sexp.pp (sexp_of_t t)

let encoding =
  let open Json_encoding in
  let sub_e =
    merge_objs (obj1 (req "type" (constant "subscribe")))
      subscription_encoding in
  let unsub_e =
    merge_objs (obj1 (req "type" (constant "unsubscribe")))
      subscription_encoding in
  let subs_e =
    merge_objs (obj1 (req "type" (constant "subscriptions")))
      subscription_encoding in
  let received_e =
    merge_objs (obj1 (req "type" (constant "received")))
      order_encoding in
  let done_e =
    merge_objs (obj1 (req "type" (constant "done")))
      order_encoding in
  let open_e =
    merge_objs (obj1 (req "type" (constant "open")))
      order_encoding in
  let match_e =
    merge_objs (obj1 (req "type" (constant "match")))
      ord_match_encoding in
  union [
    case sub_e (function Subscribe t -> Some ((), t) | _ -> None) (fun ((), t) -> Subscribe t) ;
    case unsub_e (function Unsubscribe t -> Some ((), t) | _ -> None) (fun ((), t) -> Unsubscribe t) ;
    case subs_e (function Subscriptions t -> Some ((), t) | _ -> None) (fun ((), t) -> Subscriptions t) ;
    case received_e (function Received t -> Some ((), t) | _ -> None) (fun ((), t) -> Received t) ;
    case done_e (function Done t -> Some ((), t) | _ -> None) (fun ((), t) -> Done t) ;
    case open_e (function Open t -> Some ((), t) | _ -> None) (fun ((), t) -> Open t) ;
    case match_e (function Match t -> Some ((), t) | _ -> None) (fun ((), t) -> Match t) ;
  ]

