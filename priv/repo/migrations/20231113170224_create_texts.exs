defmodule Vyasa.Repo.Migrations.CreateTexts do
  use Ecto.Migration

  def change do
    create table(:texts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string

      timestamps(type: :utc_datetime)
    end
  end
end
