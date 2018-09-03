import EctoEnum
defenum(AddressTypeEnum, :address_type, [:physical, :url, :phone, :other])

defmodule Eventos.Events.Event do
  @moduledoc """
  Represents an event
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Events.{Event, Participant, Tag, Category, Session, Track}
  alias Eventos.Actors.Actor
  alias Eventos.Addresses.Address

  schema "events" do
    field(:url, :string)
    field(:local, :boolean, default: true)
    field(:begins_on, Timex.Ecto.DateTimeWithTimezone)
    field(:description, :string)
    field(:ends_on, Timex.Ecto.DateTimeWithTimezone)
    field(:title, :string)
    # ???
    field(:state, :integer, default: 0)
    # Event status: TENTATIVE 1, CONFIRMED 2, CANCELLED 3
    field(:status, :integer, default: 0)
    # If the event is public or private
    field(:public, :boolean, default: true)
    field(:thumbnail, :string)
    field(:large_image, :string)
    field(:publish_at, Timex.Ecto.DateTimeWithTimezone)
    field(:uuid, Ecto.UUID, default: Ecto.UUID.generate())
    field(:address_type, AddressTypeEnum, default: :physical)
    field(:online_address, :string)
    field(:phone, :string)
    belongs_to(:organizer_actor, Actor, foreign_key: :organizer_actor_id)
    belongs_to(:attributed_to, Actor, foreign_key: :attributed_to_id)
    many_to_many(:tags, Tag, join_through: "events_tags")
    belongs_to(:category, Category)
    has_many(:participants, Participant, foreign_key: :event_id)
    has_many(:tracks, Track)
    has_many(:sessions, Session)
    belongs_to(:physical_address, Address)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Event{} = event, attrs) do
    # TODO : Change all of this
    actor_url =
      if Map.has_key?(attrs, :organizer_actor) do
        attrs.organizer_actor.preferred_username
      else
        ""
      end

    uuid = Ecto.UUID.generate()

    url =
      if Map.has_key?(attrs, "url"),
        do: attrs["url"],
        else: "#{EventosWeb.Endpoint.url()}/@#{actor_url}/#{uuid}"

    event
    |> Ecto.Changeset.cast(attrs, [
      :title,
      :description,
      :url,
      :begins_on,
      :ends_on,
      :organizer_actor_id,
      :category_id,
      :state,
      :status,
      :public,
      :thumbnail,
      :large_image,
      :publish_at,
      :address_type,
      :online_address,
      :phone
    ])
    |> cast_assoc(:tags)
    |> cast_assoc(:physical_address)
    |> put_change(:uuid, uuid)
    |> put_change(:url, url)
    |> validate_required([
      :title,
      :begins_on,
      :ends_on,
      :organizer_actor_id,
      :category_id,
      :url,
      :uuid,
      :address_type
    ])
  end
end
