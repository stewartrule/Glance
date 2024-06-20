import birl
import externals.{scroll_to_top, set_scroll_top, set_translate_x}
import gleam/float
import gleam/int
import gleam/io.{debug}
import gleam/list
import lustre/effect.{type Effect}
import time.{get_total_minutes}

import model.{
  type Event, type Msg, type State, Event, MountedCalendar, ResizedCalendar,
  ScrolledCalendarHorizontally, State, Task, UserClickedEventInSidebar,
  UserDeselectedEvent, UserSearchedEvent, UserSelectedEvent, UserToggledTask,
  UserUpdatedEndTime,
}

const vertical_scroll_id = "#vertical-scroll"

pub fn update(state: State, msg: Msg) -> #(State, Effect(Msg)) {
  case msg {
    UserSelectedEvent(event) -> #(
      State(
        ..state,
        selected_event_ids: case
          list.contains(state.selected_event_ids, event.id)
        {
          True -> state.selected_event_ids
          False -> list.append(state.selected_event_ids, [event.id])
        },
      ),
      effect.none(),
    )

    UserDeselectedEvent(event) -> #(
      State(
        ..state,
        selected_event_ids: list.filter(state.selected_event_ids, fn(id) {
          id != event.id
        }),
      ),
      effect.none(),
    )

    UserToggledTask(event, task) -> #(
      State(
        ..state,
        events: list.map(state.events, fn(current_item) {
          case current_item.id == event.id {
            True ->
              Event(
                ..current_item,
                tasks: list.map(current_item.tasks, fn(current_task) {
                  case current_task.id == task.id {
                    True -> Task(..current_task, done: !current_task.done)
                    False -> current_task
                  }
                }),
              )
            False -> current_item
          }
        }),
      ),
      effect.none(),
    )

    ResizedCalendar(rect) -> {
      let min_width = 165.0
      let col_count =
        float.floor(rect.width /. min_width)
        |> float.round
        |> int.clamp(1, 7)
        |> int.to_float
      let width = rect.width /. col_count

      #(
        State(..state, week_day_width: width, calendar_rect: rect),
        effect.none(),
      )
    }

    MountedCalendar(rect) -> {
      let total_minutes = get_total_minutes(state.now)
      let offset = float.round(rect.height /. 2.0)
      let scroll_top = { state.minute_height * total_minutes } - offset

      #(
        State(..state, calendar_rect: rect),
        set_scroll_top(vertical_scroll_id, scroll_top),
      )
    }

    UserClickedEventInSidebar(event) -> {
      let total_minutes = get_total_minutes(event.start)
      let scroll_top = {
        state.minute_height * total_minutes
      }
      #(state, scroll_to_top(vertical_scroll_id, scroll_top))
    }

    ScrolledCalendarHorizontally(scroll_left) -> {
      #(
        state,
        set_translate_x("#week-column-header", float.negate(scroll_left)),
      )
    }

    UserSearchedEvent(keyword) -> {
      #(State(..state, keyword: keyword), effect.none())
    }

    UserUpdatedEndTime(value) -> {
      debug(value)
      #(state, effect.none())
    }
  }
}
