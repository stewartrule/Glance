import lustre/attribute.{attribute, class}
import lustre/element.{type Element}
import lustre/element/svg.{path, svg}
import model.{type Msg}

fn icon(d: String, view_box: String) -> Element(Msg) {
  svg([class("h-2 block"), attribute("viewBox", view_box)], [
    path([attribute("d", d), attribute("fill", "currentColor")]),
  ])
}

pub fn icon_clock() -> Element(Msg) {
  icon(
    "M464 256A208 208 0 1 1 48 256a208 208 0 1 1 416 0zM0 256a256 256 0 1 0 512 0A256 256 0 1 0 0 256zM232 120V256c0 8 4 15.5 10.7 20l96 64c11 7.4 25.9 4.4 33.3-6.7s4.4-25.9-6.7-33.3L280 243.2V120c0-13.3-10.7-24-24-24s-24 10.7-24 24z",
    "0 0 512 512",
  )
}

pub fn icon_plus() {
  icon(
    "M240 64c0-8.8-7.2-16-16-16s-16 7.2-16 16V240H32c-8.8 0-16 7.2-16 16s7.2 16 16 16H208V448c0 8.8 7.2 16 16 16s16-7.2 16-16V272H416c8.8 0 16-7.2 16-16s-7.2-16-16-16H240V64z",
    "0 0 448 512",
  )
}

pub fn icon_filter() {
  icon(
    "M144 256v87.2l64 44V256 244l7.9-9L320 116V96H32v20l104.1 119 7.9 9v12zm-32 0L0 128V96 64H32 320h32V96v32L240 256V409.2 448l-32-22-96-66V256zM384 80h16 96 16v32H496 400 384V80zM336 240H496h16v32H496 336 320V240h16zm0 160H496h16v32H496 336 320V400h16z",
    "0 0 512 512",
  )
}

pub fn icon_calendar() {
  icon(
    "M112 0c8.8 0 16 7.2 16 16V64H320V16c0-8.8 7.2-16 16-16s16 7.2 16 16V64h32c35.3 0 64 28.7 64 64v32 32V448c0 35.3-28.7 64-64 64H64c-35.3 0-64-28.7-64-64V192 160 128C0 92.7 28.7 64 64 64H96V16c0-8.8 7.2-16 16-16zM416 192H32V448c0 17.7 14.3 32 32 32H384c17.7 0 32-14.3 32-32V192zM384 96H64c-17.7 0-32 14.3-32 32v32H416V128c0-17.7-14.3-32-32-32z",
    "0 0 448 512",
  )
}

pub fn icon_search() {
  icon(
    "M384 208A176 176 0 1 0 32 208a176 176 0 1 0 352 0zM343.3 366C307 397.2 259.7 416 208 416C93.1 416 0 322.9 0 208S93.1 0 208 0S416 93.1 416 208c0 51.7-18.8 99-50 135.3L507.3 484.7c6.2 6.2 6.2 16.4 0 22.6s-16.4 6.2-22.6 0L343.3 366z",
    "0 0 512 512",
  )
}

pub fn icon_bell() {
  icon(
    "M208 0h32V32.8c80.9 8 144 76.2 144 159.2v97.4l59.3 59.3 4.7 4.7V360v40 16H432 16 0V400 360v-6.6l4.7-4.7L64 289.4V192c0-83 63.1-151.2 144-159.2V0zm16 64C153.3 64 96 121.3 96 192V296v6.6l-4.7 4.7L32 366.6V384H416V366.6l-59.3-59.3-4.7-4.7V296 192c0-70.7-57.3-128-128-128zM160 448h32c0 17.7 14.3 32 32 32s32-14.3 32-32h32c0 35.3-28.7 64-64 64s-64-28.7-64-64z",
    "0 0 448 512",
  )
}

pub fn icon_check() {
  icon(
    "M443.3 100.7c6.2 6.2 6.2 16.4 0 22.6l-272 272c-6.2 6.2-16.4 6.2-22.6 0l-144-144c-6.2-6.2-6.2-16.4 0-22.6s16.4-6.2 22.6 0L160 361.4 420.7 100.7c6.2-6.2 16.4-6.2 22.6 0z",
    "0 0 448 512",
  )
}

pub fn icon_close() {
  icon(
    "M324.5 411.1c6.2 6.2 16.4 6.2 22.6 0s6.2-16.4 0-22.6L214.6 256 347.1 123.5c6.2-6.2 6.2-16.4 0-22.6s-16.4-6.2-22.6 0L192 233.4 59.5 100.9c-6.2-6.2-16.4-6.2-22.6 0s-6.2 16.4 0 22.6L169.4 256 36.9 388.5c-6.2 6.2-6.2 16.4 0 22.6s16.4 6.2 22.6 0L192 278.6 324.5 411.1z",
    "0 0 384 512",
  )
}