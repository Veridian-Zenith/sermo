defmodule Sermo.Repo.Migrations.CreateUserRecoveryKeys do
  use Ecto.Migration

  def change do
    create table(:user_recovery_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :key_ciphertext, :text, null: false
      add :used_at, :utc_datetime

      timestamps()
    end

    create index(:user_recovery_keys, :user_id)
  end
end
