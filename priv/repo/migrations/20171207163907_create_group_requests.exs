defmodule Eventos.Repo.Migrations.CreateGroupRequest do
  use Ecto.Migration

  def change do
    create table(:group_requests) do
      add :state, :integer
      add :group_id, references(:groups, on_delete: :nothing)
      add :account_id, references(:accounts, on_delete: :nothing)

      timestamps()
    end

    create index(:group_requests, [:group_id])
    create index(:group_requests, [:account_id])
  end
end
