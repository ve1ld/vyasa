defmodule Vyasa.Repo.Migrations.CreateSanghSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add :id, :uuid, primary_key: true

      timestamps(type: :utc_datetime)
    end

    execute("CREATE EXTENSION ltree", "DROP EXTENSION ltree")

    create table(:sheafs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :body, :text
      add :active, :boolean, default: false
      add :path, :ltree
      add :signature, :string
      add :session_id, references(:sessions, column: :id, type: :uuid)
      add :parent_id, references(:sheafs, column: :id, type: :uuid)
      add :traits, :jsonb

      timestamps(type: :utc_datetime_usec)
    end

    execute(
      "CREATE INDEX sheafs_traits_index ON sheafs USING GIN(traits jsonb_path_ops)",
      "DROP INDEX sheafs_traits_index"
    )

    create table(:bindings, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :w_type, :string
      add :field_key, :jsonb
      add :verse_id, references(:verses, column: :id, type: :uuid, on_delete: :nothing)

      add :chapter_no,
          references(:chapters, column: :no, type: :integer, with: [source_id: :source_id])

      add :translation_id,
          references(:translations, column: :id, type: :uuid, on_delete: :nothing)

      add :sheaf_id, references(:sheafs, column: :id, type: :uuid)
      add :source_id, references(:sources, column: :id, type: :uuid)
      add :window, :jsonb
    end

    create index(:sheafs, [:path])
    create index(:sheafs, [:session_id])
    create index(:bindings, [:chapter_no, :source_id])
  end
end
