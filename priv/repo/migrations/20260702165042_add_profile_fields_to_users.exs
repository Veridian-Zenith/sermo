defmodule Sermo.Repo.Migrations.AddProfileFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :avatar_path, :string
      add :bio, :string
      add :social_links, :map, default: "{}"
    end
  end
end
