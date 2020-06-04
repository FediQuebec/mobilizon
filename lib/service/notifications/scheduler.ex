defmodule Mobilizon.Service.Notifications.Scheduler do
  @moduledoc """
  Allows to insert jobs
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Service.Workers.Notification
  alias Mobilizon.Users
  alias Mobilizon.Users.Setting
  require Logger

  def before_event_notification(%Participant{
        id: participant_id,
        event: %Event{begins_on: begins_on},
        actor: %Actor{user_id: user_id}
      })
      when not is_nil(user_id) do
    case Users.get_setting(user_id) do
      %Setting{notification_before_event: true} ->
        Notification.enqueue(:before_event_notification, %{participant_id: participant_id},
          scheduled_at: DateTime.add(begins_on, -3600, :second)
        )

      _ ->
        {:ok, nil}
    end
  end

  def before_event_notification(_), do: {:ok, nil}

  def on_day_notification(%Participant{
        event: %Event{begins_on: begins_on},
        actor: %Actor{user_id: user_id}
      })
      when not is_nil(user_id) do
    case Users.get_setting(user_id) do
      %Setting{notification_on_day: true, timezone: timezone} ->
        %DateTime{hour: hour} = begins_on_shifted = shift_zone(begins_on, timezone)
        Logger.debug("Participation event start at #{inspect(begins_on_shifted)} (user timezone)")

        send_date =
          cond do
            begins_on < DateTime.utc_now() ->
              nil

            hour > 8 ->
              # If the event is after 8 o'clock
              %{begins_on_shifted | hour: 8, minute: 0, second: 0, microsecond: {0, 0}}

            true ->
              # If the event is before 8 o'clock, we send the notification the day before,
              # unless this is already passed
              begins_on_shifted
              |> DateTime.add(-24 * 3_600)
              |> (&%{&1 | hour: 8, minute: 0, second: 0, microsecond: {0, 0}}).()
          end

        Logger.debug(
          "Participation notification should be sent at #{inspect(send_date)} (user timezone)"
        )

        if DateTime.utc_now() > send_date do
          {:ok, "Too late to send same day notifications"}
        else
          Notification.enqueue(:on_day_notification, %{user_id: user_id}, scheduled_at: send_date)
        end

      _ ->
        {:ok, "User has disable on day notifications"}
    end
  end

  def on_day_notification(_), do: {:ok, nil}

  defp shift_zone(datetime, timezone) do
    case DateTime.shift_zone(datetime, timezone) do
      {:ok, shift_datetime} -> shift_datetime
      {:error, _} -> datetime
    end
  end
end