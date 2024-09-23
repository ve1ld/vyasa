defmodule Vyasa.Repo.Migrations.CreateMarks do
  use Ecto.Migration

  def change do

    create table(:marks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :body, :string
      add :order, :integer
      add :state, :string
      add :window, :jsonb

      add :verse_id, references(:verses, column: :id, type: :uuid, on_delete: :nothing)
      add :binding_id, references(:bindings, column: :id, type: :uuid, on_delete: :nothing)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:marks, [:verse_id])
    create index(:marks, [:binding_id])

  end
 end
