module Ezjsonm_encoding : sig
  include module type of Json_encoding.Make(Json_repr.Ezjsonm)
  val destruct_safe : 'a Json_encoding.encoding -> Ezjsonm.value -> 'a
end

module Ptime : sig
  include module type of Ptime
    with type t = Ptime.t
     and type span = Ptime.span

  val t_of_sexp : Sexplib.Sexp.t -> t
  val sexp_of_t : t -> Sexplib.Sexp.t
  val encoding : t Json_encoding.encoding
end

module Uuidm : sig
  include module type of Uuidm
    with type t = Uuidm.t

  val t_of_sexp : Sexplib.Sexp.t -> t
  val sexp_of_t : t -> Sexplib.Sexp.t
  val encoding : t Json_encoding.encoding
end

val strfloat : float Json_encoding.encoding
