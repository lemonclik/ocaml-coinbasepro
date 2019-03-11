type channel =
  | Ticker
  | Level2
  | User
  | Matches
  | Full
[@@deriving sexp]

type channel_full = {
  chan: channel ;
  product_ids : string list ;
} [@@deriving sexp]

val full : string list -> channel_full

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

val order_encoding : order Json_encoding.encoding

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

type t =
  | Subscribe of channel_full list
  | Unsubscribe of channel_full list
  | Subscriptions of channel_full list
  | Received of order
  | Done of order
  | Open of order
  | Match of ord_match
[@@deriving sexp]

val pp : Format.formatter -> t -> unit
val encoding : t Json_encoding.encoding
