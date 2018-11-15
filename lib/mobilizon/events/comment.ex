defmodule Mobilizon.Events.Comment do
  @moduledoc """
  An actor comment (for instance on an event or on a group)
  """

  use Mobilizon.Ecto.Schema
  import Ecto.Changeset

  alias Mobilizon.Events.Event
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Comment

  schema "comments" do
    field(:text, :string)
    field(:url, :string)
    field(:local, :boolean, default: true)
    field(:uuid, Ecto.UUID)
    belongs_to(:actor, Actor, foreign_key: :actor_id)
    belongs_to(:attributed_to, Actor, foreign_key: :attributed_to_id)
    belongs_to(:event, Event, foreign_key: :event_id)
    belongs_to(:in_reply_to_comment, Comment, foreign_key: :in_reply_to_comment_id)
    belongs_to(:origin_comment, Comment, foreign_key: :origin_comment_id)

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    uuid =
      if Map.has_key?(attrs, "uuid"),
        do: attrs["uuid"],
        else: Ecto.UUID.generate()

    # TODO : really change me right away
    url =
      if Map.has_key?(attrs, "url"),
        do: attrs["url"],
        else: "#{MobilizonWeb.Endpoint.url()}/comments/#{uuid}"

    comment
    |> cast(attrs, [
      :url,
      :text,
      :actor_id,
      :event_id,
      :in_reply_to_comment_id,
      :origin_comment_id,
      :attributed_to_id
    ])
    |> put_change(:uuid, uuid)
    |> put_change(:url, url)
    |> validate_required([:text, :actor_id, :url])
  end

  @doc """
  Returns the id of the first comment in the conversation
  """
  def get_thread_id(%Comment{id: id, origin_comment_id: origin_comment_id}) do
    origin_comment_id || id
  end
end
