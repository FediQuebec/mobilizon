defmodule MobilizonWeb.Schema do
  use Absinthe.Schema

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias Mobilizon.{Actors, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event

  import_types(MobilizonWeb.Schema.Custom.UUID)
  import_types(Absinthe.Type.Custom)
  import_types(Absinthe.Plug.Types)

  alias MobilizonWeb.Resolvers

  @desc "An ActivityPub actor"
  object :actor do
    field(:url, :string, description: "The ActivityPub actor's URL")
    # We probably don't need all of that
    # field(:outbox_url, :string, description: "The ActivityPub actor outbox_url")
    # field(:inbox_url, :string)
    # field(:following_url, :string)
    # field(:followers_url, :string)
    # field(:shared_inbox_url, :string)
    field(:type, :actor_type, description: "The type of Actor (Person, Group,…)")
    field(:name, :string, description: "The actor's displayed name")
    field(:domain, :string, description: "The actor's domain if (null if it's this instance)")
    field(:summary, :string, description: "The actor's summary")
    field(:preferred_username, :string, description: "The actor's preferred username")
    field(:keys, :string, description: "The actors RSA Keys")

    field(:manually_approves_followers, :boolean,
      description: "Whether the actors manually approves followers"
    )

    field(:suspended, :boolean, description: "If the actor is suspended")
    field(:avatar_url, :string, description: "The actor's avatar url")
    field(:banner_url, :string, description: "The actor's banner url")
    # field(:followers, list_of(:follower))
    field(:organized_events, list_of(:event),
      resolve: dataloader(Events),
      description: "A list of the events this actor has organized"
    )

    # field(:memberships, list_of(:member))
    field(:user, :user, description: "The user this actor is associated to")
  end

  @desc "The list of types an actor can be"
  enum :actor_type do
    value(:Person, description: "An ActivityPub Person")
    value(:Application, description: "An ActivityPub Application")
    value(:Group, description: "An ActivityPub Group")
    value(:Organization, description: "An ActivityPub Organization")
    value(:Service, description: "An ActivityPub Service")
  end

  @desc "A local user of Mobilizon"
  object :user do
    field(:id, non_null(:id), description: "The user's ID")
    field(:email, non_null(:string), description: "The user's email")
    # , resolve: dataloader(:actors))
    field(:actors, non_null(list_of(:actor)),
      description: "The user's list of actors (identities)"
    )

    field(:default_actor_id, non_null(:integer), description: "The user's default actor")

    field(:confirmed_at, :datetime,
      description: "The datetime when the user was confirmed/activated"
    )

    field(:confirmation_sent_at, :datetime,
      description: "The datetime the last activation/confirmation token was sent"
    )

    field(:confirmation_token, :string, description: "The account activation/confirmation token")

    field(:reset_password_sent_at, :datetime,
      description: "The datetime last reset password email was sent"
    )

    field(:reset_password_token, :string,
      description: "The token sent when requesting password token"
    )
  end

  @desc "A JWT and the associated user ID"
  object :login do
    field(:token, non_null(:string))
    field(:user, non_null(:user))
    field(:actor, non_null(:actor))
  end

  @desc "An event"
  object :event do
    field(:uuid, :uuid)
    field(:url, :string)
    field(:local, :boolean)
    field(:title, :string)
    field(:description, :string)
    field(:begins_on, :datetime)
    field(:ends_on, :datetime)
    field(:state, :integer)
    field(:status, :integer)
    field(:public, :boolean)
    field(:thumbnail, :string)
    field(:large_image, :string)
    field(:publish_at, :datetime)
    field(:address_type, :address_type)
    field(:online_address, :string)
    field(:phone, :string)

    field :organizer_actor, :actor do
      resolve(dataloader(Actors))
    end

    field(:attributed_to, :actor)
    # field(:tags, list_of(:tag))
    field(:category, :category)

    field(:participants, list_of(:participant),
      resolve: &Resolvers.Event.list_participants_for_event/3
    )

    # field(:tracks, list_of(:track))
    # field(:sessions, list_of(:session))
    # field(:physical_address, :address)

    field(:updated_at, :datetime)
    field(:inserted_at, :datetime)
  end

  @desc "Represents a participant to an event"
  object :participant do
    # field(:event, :event, resolve: dataloader(Events))
    # , resolve: dataloader(Actors)
    field(:actor, :actor)
    field(:role, :integer)
  end

  @desc "The list of types an address can be"
  enum :address_type do
    value(:physical)
    value(:url)
    value(:phone)
    value(:other)
  end

  @desc "A category"
  object :category do
    field(:id, :id)
    field(:description, :string)
    field(:picture, :picture)
    field(:title, :string)
    field(:updated_at, :datetime)
    field(:inserted_at, :datetime)
  end

  @desc "A picture"
  object :picture do
    field(:url, :string)
    field(:url_thumbnail, :string)
  end

  @desc "A search result"
  union :search_result do
    types([:event, :actor])

    resolve_type(fn
      %Actor{}, _ ->
        :actor

      %Event{}, _ ->
        :event
    end)
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Actors, Actors.data())
      |> Dataloader.add_source(Events, Events.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  query do
    @desc "Get all events"
    field :events, list_of(:event) do
      resolve(&Resolvers.Event.list_events/3)
    end

    @desc "Search through events and actors"
    field :search, list_of(:search_result) do
      arg(:search, non_null(:string))
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Event.search_events_and_actors/3)
    end

    @desc "Get an event by uuid"
    field :event, :event do
      arg(:uuid, non_null(:uuid))
      resolve(&Resolvers.Event.find_event/3)
    end

    @desc "Get all participants for an event uuid"
    field :participants, list_of(:participant) do
      arg(:uuid, non_null(:uuid))
      resolve(&Resolvers.Event.list_participants_for_event/3)
    end

    @desc "Get an user"
    field :user, :user do
      arg(:id, non_null(:id))
      resolve(&Resolvers.User.find_user/3)
    end

    @desc "Get the current user"
    field :logged_user, :user do
      resolve(&Resolvers.User.get_current_user/3)
    end

    @desc "Get the current actor for the logged-in user"
    field :logged_actor, :actor do
      resolve(&Resolvers.Actor.get_current_actor/3)
    end

    @desc "Get an actor"
    field :actor, :actor do
      arg(:preferred_username, non_null(:string))
      resolve(&Resolvers.Actor.find_actor/3)
    end

    @desc "Get the list of categories"
    field :categories, list_of(:category) do
      resolve(&Resolvers.Category.list_categories/3)
    end
  end

  mutation do
    @desc "Create an event"
    field :create_event, type: :event do
      arg(:title, non_null(:string))
      arg(:description, non_null(:string))
      arg(:begins_on, non_null(:datetime))
      arg(:ends_on, :datetime)
      arg(:state, :integer)
      arg(:status, :integer)
      arg(:public, :boolean)
      arg(:thumbnail, :string)
      arg(:large_image, :string)
      arg(:publish_at, :datetime)
      arg(:address_type, non_null(:address_type))
      arg(:online_address, :string)
      arg(:phone, :string)
      arg(:organizer_actor_id, non_null(:integer))
      arg(:category_id, non_null(:integer))

      resolve(&Resolvers.Event.create_event/3)
    end

    @desc "Create a category with a title, description and picture"
    field :create_category, type: :category do
      arg(:title, non_null(:string))
      arg(:description, non_null(:string))
      arg(:picture, non_null(:upload))
      resolve(&Resolvers.Category.create_category/3)
    end

    @desc "Create an user (returns an actor)"
    field :create_user, type: :actor do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      arg(:username, non_null(:string))

      resolve(&Resolvers.User.create_user_actor/3)
    end

    @desc "Validate an user after registration"
    field :validate_user, type: :login do
      arg(:token, non_null(:string))
      resolve(&Resolvers.User.validate_user/3)
    end

    @desc "Resend registration confirmation token"
    field :resend_confirmation_email, type: :string do
      arg(:email, non_null(:string))
      arg(:locale, :string, default_value: "en")
      resolve(&Resolvers.User.resend_confirmation_email/3)
    end

    @desc "Send a link through email to reset user password"
    field :send_reset_password, type: :string do
      arg(:email, non_null(:string))
      arg(:locale, :string, default_value: "en")
      resolve(&Resolvers.User.send_reset_password/3)
    end

    @desc "Reset user password"
    field :reset_password, type: :login do
      arg(:token, non_null(:string))
      arg(:password, non_null(:string))
      arg(:locale, :string, default_value: "en")
      resolve(&Resolvers.User.reset_password/3)
    end

    @desc "Login an user"
    field :login, :login do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      resolve(&Resolvers.User.login_user/3)
    end

    @desc "Change default actor for user"
    field :change_default_actor, :user do
      arg(:preferred_username, non_null(:string))
      resolve(&Resolvers.User.change_default_actor/3)
    end

    # @desc "Upload a picture"
    # field :upload_picture, :picture do
    #   arg(:file, non_null(:upload))
    #   resolve(&Resolvers.Upload.upload_picture/3)
    # end
  end
end
