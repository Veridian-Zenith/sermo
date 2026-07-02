defmodule Sermo.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :type, :string, null: false, default: "direct"
      add :created_by_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create index(:conversations, [:created_by_id])
  end
end
