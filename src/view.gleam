import birl.{type Time}
import birl/duration
import css
import gleam/dynamic
import gleam/float
import gleam/int
import gleam/io.{debug}
import gleam/list
import gleam/result
import gleam/string.{lowercase}
import lustre/attribute.{class, classes, style}
import lustre/element.{type Element, element, none, text}
import lustre/element/html
import lustre/event.{on, on_click}

import decoder.{decode_element_dom_rect_from_event}
import icon.{icon_clock}
import model.{
  type Attendee, type Event, type Msg, type State, type User, Attendee, Event,
  MountedCalendar, ResizedCalendar, ScrolledCalendarHorizontally, State, User,
  UserClickedEventInSidebar, UserSearchedEvent, UserToggledTask,
  UserUpdatedEndTime,
}
import time.{format_hh_mm, get_hours_for_date, get_total_minutes, ordinal}

pub fn view(state: State) -> Element(Msg) {
  html.div([], [
    html.div(
      [
        class(
          "grid grid-cols-1 md:grid-cols-[22rem_1fr] bg-color-3 w-full h-dvh overflow-hidden relative",
        ),
      ],
      [
        view_sidebar(state),
        html.div([class("grid grid-rows-[auto_auto_1fr] h-dvh")], [
          html.div(
            [class("border-b p-2 flex justify-between items-center gap-2")],
            [
              view_member_list(state),
              html.div([class("flex gap-2")], [
                html.button([class("p-1 border rounded-full h-5 px-2")], [
                  text("Filter"),
                ]),
                html.button([class("p-1 border rounded-full h-5 px-2")], [
                  text("Month"),
                ]),
                html.button(
                  [class("p-1 bg-color-12 text-color-2 rounded-full h-5 px-2")],
                  [text("New Event")],
                ),
              ]),
            ],
          ),
          html.div(
            [class("w-full flex items-center overflow-hidden bg-color-2")],
            [
              html.div(
                [
                  attribute.id("week-column-header"),
                  class("h-6 w-full flex items-center pl-10 border-b"),
                ],
                list.map(state.date_range, fn(date) {
                  let is_current_day =
                    birl.get_day(date) == birl.get_day(state.now)

                  let count =
                    list.length(get_events_on_day(
                      state.events,
                      birl.get_day(date),
                    ))
                  let day = case state.week_day_width <. 175.0 {
                    True ->
                      string.slice(
                        from: birl.string_weekday(date),
                        at_index: 0,
                        length: 1,
                      )
                    False -> birl.string_weekday(date)
                  }

                  html.div(
                    [
                      class(
                        "h-6 flex translate-x-0 items-center justify-center shrink-0 grow",
                      ),
                      style([css.width_px(float.round(state.week_day_width))]),
                    ],
                    [
                      html.span([class("flex gap-1")], [
                        html.span(
                          [
                            class(case is_current_day {
                              True -> "text-color-12"
                              False -> "text-color-5"
                            }),
                          ],
                          [text(day)],
                        ),
                        html.span(
                          [
                            class(case is_current_day {
                              True -> "text-color-12"
                              False -> "text-color-1"
                            }),
                          ],
                          [text(int.to_string(birl.get_day(date).date))],
                        ),
                        html.span(
                          [
                            class(
                              "bg-color-3 text-color-5 px-[10px] border leading-none rounded-full text-xs flex items-center",
                            ),
                          ],
                          [text(int.to_string(count))],
                        ),
                      ]),
                    ],
                  )
                }),
              ),
            ],
          ),
          html.div([class("relative grid grid-cols-1")], [
            html.div([class("relative")], [view_calendar_week(state)]),
          ]),
        ]),
      ],
    ),
    // view_create_event(state),
  ])
}

fn view_sidebar(state: State) -> Element(Msg) {
  let range = state.date_range
  let filtered_events =
    list.filter(state.events, fn(event) {
      string.contains(
        does: lowercase(event.name),
        contain: lowercase(state.keyword),
      )
    })
  let filtered_range =
    list.filter(range, fn(date) {
      get_events_on_day(filtered_events, birl.get_day(date)) |> list.length > 0
    })
  html.div(
    [
      class(
        "hidden md:flex flex-col gap-2 p-2 pb-0 border-r bg-color-2 h-dvh overflow-hidden",
      ),
    ],
    [
      html.div(
        [class("border grid grid-cols-[1fr_2.5rem] rounded-1 relative")],
        [
          html.input([
            attribute.value(state.keyword),
            event.on_input(UserSearchedEvent),
            class("h-5 p-1 px-2 w-full bg-transparent"),
            attribute.placeholder("Search event"),
          ]),
          html.button(
            [class("size-5 flex items-center justify-center rounded-1")],
            [html.span([class("size-4 bg-color-12 rounded-2")], [])],
          ),
        ],
      ),
      html.div(
        [class("overflow-y-auto flex flex-col grow shrink smooth-scroll")],
        list.map(filtered_range, fn(date) {
          let events = get_events_on_day(filtered_events, birl.get_day(date))
          html.div([], [
            html.h3(
              [
                class(
                  "bg-color-13 text-color-12 p-1 pl-4 h-6 items-center flex font-semibold rounded-1",
                ),
              ],
              [
                text(
                  birl.string_weekday(date)
                  <> ", "
                  <> ordinal(birl.get_day(date).date),
                ),
              ],
            ),
            ..list.map(events, fn(event) {
              let border_color = case event.event_type {
                model.Assignment -> "border-color-6"
                model.Story -> "border-color-8"
                model.Bug -> "border-color-10"
                _ -> "border-color-12"
              }
              html.div(
                [
                  class("py-2 ml-4 border-b last:border-0"),
                  on_click(UserClickedEventInSidebar(event)),
                ],
                [
                  html.h4(
                    [
                      class("border-l-2 pl-1 text-xl leading-none font-normal"),
                      class(border_color),
                    ],
                    [text(event.name)],
                  ),
                  html.span(
                    [class("leading-none flex gap-1 pl-0 mt-2 text-color-5")],
                    [
                      icon_clock(),
                      html.span([], [
                        text(format_hh_mm(event.start)),
                        text(" - "),
                        text(format_hh_mm(
                          event.start |> birl.add(event.duration),
                        )),
                      ]),
                    ],
                  ),
                ],
              )
            })
          ])
        }),
      ),
    ],
  )
}

fn get_attendees_for_today(state: State) {
  let attending_user_ids =
    get_events_on_day(state.events, birl.get_day(state.now))
    |> list.flat_map(fn(event) {
      list.map(event.attendees, fn(attendee) { attendee.user.id })
    })

  state.users
  |> list.filter(fn(user) { list.contains(attending_user_ids, user.id) })
}

fn view_member_list(state: State) {
  let users = get_attendees_for_today(state)
  let available_width = state.calendar_rect.width -. 330.0
  let amount = float.round(available_width /. 24.0)
  let initial = list.take(users, amount)

  html.div([class("flex items-center gap-2")], [
    html.div(
      [
        class(
          "flex flex-grow items-center gap-0 relative justify-end items-center h-4",
        ),
      ],
      list.index_map(initial, fn(user, i) {
        html.div(
          [
            class("absolute top-0 flex-shrink-0 size-4 bg-color-4 rounded-full"),
            style([css.left_px(i * 24)]),
          ],
          [view_user_avatar(user)],
        )
      }),
    ),
    // html.span([], [text(int.to_string(list.length(state.users)) <> " members")]),
  ])
}

fn view_user_avatar(user: User) {
  html.img([
    class("rounded-full size-4 flex-shrink-0 border border-white"),
    attribute.alt(""),
    attribute.height(32),
    attribute.width(32),
    attribute.src(get_user_avatar_url(user)),
  ])
}

fn get_user_avatar_url(user: User) -> String {
  "https://mighty.tools/mockmind-api/content/human/"
  <> int.to_string(user.id)
  <> ".jpg"
}

fn view_calendar_week(state: State) -> Element(Msg) {
  let initial = list.take(state.date_range, 1)
  let hour_height = state.minute_height * 60

  element(
    "lifecycle-events",
    [
      attribute.id("vertical-scroll"),
      on("mounted", decode_element_dom_rect_from_event(_, fn(rect, _element_id) {
        Ok(MountedCalendar(rect))
      })),
      class("flex overflow-y-auto absolute w-full inset-0"),
    ],
    [
      element.fragment(list.map(initial, view_calendar_hours(_, state))),
      element(
        "lifecycle-events",
        [
          attribute.id("horizontal-scroll"),
          style([css.height_px(24 * hour_height)]),
          on(
            "resize",
            decode_element_dom_rect_from_event(_, fn(rect, _element_id) {
              Ok(ResizedCalendar(rect))
            }),
          ),
          on("scroll", fn(event) {
            use target <- result.try(dynamic.field("target", dynamic.dynamic)(
              event,
            ))
            use scroll_left <- result.try(dynamic.field(
              "scrollLeft",
              dynamic.float,
            )(target))
            Ok(ScrolledCalendarHorizontally(scroll_left))
          }),
          class(
            "flex relative overscroll-x-contain overflow-y-hidden overflow-x-auto gap-0 w-full scroll-smooth snap-x snap-mandatory bg-color-4",
          ),
        ],
        list.map(state.date_range, view_calendar_day(_, state)),
      ),
    ],
  )
}

fn get_events_on_day(events: List(Event), day: birl.Day) -> List(Event) {
  list.filter(events, fn(event) { birl.get_day(event.start) == day })
}

fn view_calendar_day(date: Time, state: State) -> Element(Msg) {
  let day_events = get_events_on_day(state.events, birl.get_day(date))
  let hours = get_hours_for_date(date)
  let hour_height = state.minute_height * 60
  let is_current_day = birl.get_day(date) == birl.get_day(state.now)
  let minutes_elapsed = get_total_minutes(state.now)

  html.div(
    [
      class("flex flex-col shrink-0 grow relative snap-start border-r"),
      classes([#("diagonal-lines", is_current_day)]),
      style([
        css.height_px(24 * hour_height),
        css.width_px(float.round(state.week_day_width)),
      ]),
    ],
    list.concat([
      list.map(hours, view_calendar_hour(_, is_current_day, state)),
      [
        html.div(
          [
            class("absolute top-0 left-0 h-[2px] bg-color-12 w-full"),
            style([
              css.top_px({ minutes_elapsed * state.minute_height } - 1),
              #("width", "calc(100% + 1px)"),
            ]),
          ],
          [],
        ),
      ],
      list.map(day_events, view_event_card(_, state)),
    ]),
  )
}

fn view_calendar_hours(date: Time, state: State) -> Element(Msg) {
  let hour_height = state.minute_height * 60
  let hours = get_hours_for_date(date)
  let minutes_elapsed = get_total_minutes(state.now)

  html.div(
    [
      class("flex flex-col bg-color-3 min-w-10 relative"),
      style([css.height_px(24 * hour_height)]),
    ],
    list.concat([
      list.map(hours, view_calendar_hour_label(_, state)),
      [
        html.div(
          [
            class(
              "absolute text-center text-xs top-0 left-2 rounded-2 right-2 h-3 text-color-2 flex justify-center items-center bg-color-12",
            ),
            style([css.top_px({ minutes_elapsed * state.minute_height } - 12)]),
          ],
          [text(format_hh_mm(state.now))],
        ),
        html.div(
          [
            class(
              "absolute text-center z-10 text-xs top-0 rounded-2 -right-[2px] size-1 text-color-2 bg-color-12",
            ),
            style([css.top_px({ minutes_elapsed * state.minute_height } - 4)]),
          ],
          [],
        ),
      ],
    ]),
  )
}

fn view_calendar_hour_label(time: Time, state: State) -> Element(Msg) {
  let hour = birl.get_time_of_day(time).hour
  let hour_height = state.minute_height * 60

  html.div(
    [
      class(
        "flex flex-col text-color-1-50 absolute left-0 text-center w-full h-8 -translate-y-4 justify-center",
      ),
      style([css.top_px(hour * hour_height)]),
    ],
    case hour {
      0 -> []
      _ -> [text(format_hh_mm(time))]
    },
  )
}

fn view_calendar_hour(
  time: Time,
  is_current_day: Bool,
  state: State,
) -> Element(Msg) {
  let hour = birl.get_time_of_day(time).hour
  let hour_height = state.minute_height * 60

  html.div(
    [
      class("flex flex-col absolute left-0 w-full"),
      classes([#("bg-color-2", !is_current_day)]),
      style([css.top_px(hour * hour_height), css.height_px(hour_height - 1)]),
    ],
    [],
  )
}

fn is_between(start: Time, stop: Time, current: Time) -> Bool {
  let timestamp = birl.to_unix(current)
  timestamp >= birl.to_unix(start) && timestamp < birl.to_unix(stop)
}

fn view_event_card(event: Event, state: State) {
  let minute_height = state.minute_height
  let start = birl.get_time_of_day(event.start)
  let minutes = { start.hour * 60 } + start.minute
  let duration_minutes = duration.blur_to(event.duration, duration.Minute)
  let top = minutes * minute_height
  let event_height = duration_minutes * minute_height
  let end = event.start |> birl.add(event.duration)
  let is_now = is_between(event.start, end, state.now)
  let visible_attendee_count: Int =
    float.round({ state.week_day_width -. 124.0 } /. 24.0)

  let border_color = case event.event_type {
    model.Assignment -> "border-color-6"
    model.Story -> "border-color-8"
    model.Bug -> "border-color-10"
    _ -> "border-color-12"
  }
  let text_color = case event.event_type {
    model.Assignment -> "text-color-6"
    model.Story -> "text-color-8"
    model.Bug -> "text-color-10"
    _ -> "text-color-12"
  }
  let bg_color = case event.event_type {
    model.Assignment -> "bg-color-7"
    model.Story -> "bg-color-9"
    model.Bug -> "bg-color-11"
    _ -> "bg-color-13"
  }

  html.div(
    [
      class("w-full absolute left-0 p-[4px]"),
      style([css.top_px(top - 1), css.height_px(event_height + 1)]),
    ],
    [
      html.div(
        [
          class("flex flex-col gap-1 border h-full rounded-2"),
          class(bg_color),
          class(border_color),
          classes([
            #("px-2 justify-center", duration_minutes <= 15),
            #("p-2", duration_minutes > 15),
            #("shadow-xl", is_now),
          ]),
        ],
        [
          html.div([class("flex gap-1 items-center")], [
            html.h2(
              [
                classes([
                  #("line-clamp-2", duration_minutes <= 30),
                  #(
                    "line-clamp-2",
                    duration_minutes > 30 && duration_minutes <= 90,
                  ),
                  #("line-clamp-3", duration_minutes > 90),
                ]),
                class(text_color),
                classes([
                  #("text-xs", duration_minutes <= 15),
                  #(
                    "text-base",
                    duration_minutes > 15 && duration_minutes <= 30,
                  ),
                  #("text-xl", duration_minutes > 30),
                  #("leading-none", duration_minutes <= 15),
                  #("leading-tight", duration_minutes > 15),
                ]),
              ],
              [text(event.name)],
            ),
          ]),
          // case is_now {
          //   False -> none()
          //   True -> html.span([], [text("NOW")])
          // },
          case duration_minutes >= 45 {
            False -> none()
            True ->
              html.span([class("leading-none font-light"), class(text_color)], [
                text(format_hh_mm(event.start)),
                text(" - "),
                text(format_hh_mm(end)),
              ])
          },
          case duration_minutes >= 60 {
            False -> none()
            True ->
              case event.attendees {
                [] -> none()
                _ -> view_attendee_avatar_list(event, visible_attendee_count)
              }
          },
        ],
      ),
    ],
  )
}

fn view_event_task_list(event: Event) -> Element(Msg) {
  html.div(
    [class("flex flex-col gap-2")],
    list.map(event.tasks, fn(task) {
      html.div([class("flex items-center gap-1 justify-between")], [
        html.span(
          [
            classes([#("line-through", task.done), #("text-color-4", task.done)]),
          ],
          [text(task.name)],
        ),
        view_checkbox(
          on_change: UserToggledTask(event, task),
          checked: task.done,
        ),
      ])
    }),
  )
}

fn view_attendee_list(users: List(Attendee)) {
  html.div(
    [class("flex flex-col gap-2")],
    list.map(users, view_attendee_list_item(_)),
  )
}

fn view_attendee_avatar_list(event: Event, visible_count: Int) {
  let attendees = event.attendees
  let initial = list.take(attendees, visible_count)
  let rest_count = list.length(attendees) - list.length(initial)

  let border_color = case event.event_type {
    model.Assignment -> "border-color-6"
    model.Story -> "border-color-8"
    model.Bug -> "border-color-10"
    _ -> "border-color-12"
  }
  let text_color = case event.event_type {
    model.Assignment -> "text-color-6"
    model.Story -> "text-color-8"
    model.Bug -> "text-color-10"
    _ -> "text-color-12"
  }

  html.div(
    [class("flex gap-0 relative justify-end items-center h-4 mt-auto")],
    list.concat([
      list.index_map(initial, fn(attendee, i) {
        html.div(
          [class("absolute top-0 flex-shrink-0"), style([css.left_px(i * 24)])],
          [view_user_avatar(attendee.user)],
        )
      }),
      [
        case rest_count {
          0 -> none()
          _ ->
            html.button(
              [
                class("px-[12px] h-full rounded-full border"),
                class(text_color),
                class(border_color),
                attribute.attribute("title", "View attendees"),
              ],
              [text(int.to_string(rest_count) <> "+")],
            )
        },
      ],
    ]),
  )
}

fn view_attendee_list_item(invite: Attendee) {
  html.div([class("flex items-center gap-2")], [
    view_user_avatar(invite.user),
    html.span([], [text(invite.user.first_name <> " " <> invite.user.last_name)]),
    view_attendee_status(invite),
  ])
}

fn view_checkbox(on_change on_click: Msg, checked checked: Bool) {
  html.button(
    [
      event.on_click(on_click),
      class("size-6 rounded-full"),
      classes([#("bg-color-3", !checked), #("bg-color-5", checked)]),
    ],
    [],
  )
}

fn view_attendee_status(invite: Attendee) {
  html.div(
    [
      class(
        "px-2 h-full flex items-center bg-color-3 text-sm justify-self-end ml-auto rounded-md",
      ),
      classes([
        #("bg-color-3-40", !invite.accepted),
        #("bg-color-5-40", invite.accepted),
      ]),
    ],
    [
      text(case invite.accepted {
        True -> "Accepted"
        False -> "Rejected"
      }),
    ],
  )
}

fn view_create_event(state: State) -> Element(Msg) {
  html.div([class("absolute inset-0 bg-color-1-30 p-2")], [
    html.div([class("w-64 bg-color-2 p-3 rounded-2")], [
      html.div([class("flex flex-col gap-1")], [
        html.div([], [
          html.label([], [text("Date & Time")]),
          html.input([
            attribute.value("2024-06-24"),
            attribute.type_("date"),
            class("w-full border p-1 rounded-1"),
          ]),
        ]),
        html.div([class("grid grid-cols-2 gap-1")], [
          html.input([
            attribute.type_("time"),
            attribute.value("08:00"),
            class("w-full border p-1 rounded-1"),
          ]),
          html.input([
            attribute.type_("time"),
            attribute.value("08:00"),
            event.on_input(UserUpdatedEndTime),
            class("w-full border p-1 rounded-1"),
          ]),
        ]),
      ]),
    ]),
  ])
}
