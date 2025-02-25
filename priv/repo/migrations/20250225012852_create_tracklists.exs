defmodule Vyasa.Repo.Migrations.CreateBhaj do
  use Ecto.Migration

  def change do
    create table(:tracklists, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string

      timestamps(type: :utc_datetime)
    end

    create table(:bhaj, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
      add :trackls_id, references(:tracklists, column: :id, type: :uuid, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:bhaj, [:trackls_id])
  end
end
