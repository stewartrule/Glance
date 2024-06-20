import gleam/dynamic.{type DecodeError, decode8, dynamic, field, float, string}
import gleam/io.{debug}
import gleam/result
import model.{type DomRect, type Msg, DomRect}

type Decoded(a) =
  Result(a, List(DecodeError))

pub fn get_dom_rect_decoder() {
  decode8(
    DomRect,
    field("x", float),
    field("y", float),
    field("width", float),
    field("height", float),
    field("top", float),
    field("right", float),
    field("bottom", float),
    field("left", float),
  )
}

pub fn decode_element_dom_rect_from_event(
  event,
  handle: fn(DomRect, String) -> Decoded(Msg),
) {
  use detail <- result.try(field("detail", dynamic)(event))
  use rect <- result.try(field("rect", get_dom_rect_decoder())(detail))
  use element_id <- result.try(field("id", string)(detail))
  handle(rect, element_id)
}
