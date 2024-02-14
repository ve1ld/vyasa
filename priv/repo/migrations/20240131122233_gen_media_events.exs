defmodule Vyasa.Repo.Migrations.GenMediaEvents do
  use Ecto.Migration

  def change do
    create table(:tracks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
    end

    create table(:voices, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :lang, :string
      add :title, :string
      add :duration, :integer
      add :prop, :jsonb
      add :track_id,  references(:tracks, column: :id, type: :uuid)
      add :chapter_no, references(:chapters, column: :no, type: :integer, with: [source_id: :source_id])
      add :source_id,  references(:sources, column: :id, type: :uuid)

      timestamps([:utc_datetime])
    end

    create table(:videos, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :type, :string
      add :ext_uri, :string
      add :voice_id, references(:voices, column: :id, type: :uuid, on_delete: :nothing)
    end

    create table(:events, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :origin, :integer
      add :duration, :integer
      add :phase, :string

      add :verse_id, references(:verses, column: :id, type: :uuid, on_delete: :nothing)
      add :voice_id, references(:voices, column: :id, type: :uuid, on_delete: :nothing)
      add :fragments, {:array, :map}, null: false, default: []
      add :source_id,  references(:sources, column: :id, type: :uuid)
    end

    alter table(:chapters) do
      add :key, :string
      add :parent_no, references(:chapters, column: :no, type: :integer, with: [source_id: :source_id])
    end

    create unique_index(:sources, [:title])
  end
end
