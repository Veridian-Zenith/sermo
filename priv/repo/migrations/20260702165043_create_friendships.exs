defmodule Sermo.Repo.Migrations.CreateFriendships do
  use Ecto.Migration

  def change do
    create table(:friendships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :requester_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :requested_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, default: "pending"

      timestamps()
    end

    create unique_index(:friendships, [:requester_id, :requested_id])
    create index(:friendships, [:requester_id])
    create index(:friendships, [:requested_id])
    create index(:friendships, [:status])
  end
end
