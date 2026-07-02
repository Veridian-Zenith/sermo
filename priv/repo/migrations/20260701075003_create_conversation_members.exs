defmodule Sermo.Repo.Migrations.CreateConversationMembers do
  use Ecto.Migration

  def change do
    create table(:conversation_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :conversation_id, references(:conversations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :role, :string, default: "member"

      timestamps()
    end

    create index(:conversation_members, [:user_id])
    create index(:conversation_members, [:conversation_id])
    create unique_index(:conversation_members, [:user_id, :conversation_id])
  end
end
