defmodule Vyasa.Repo.Migrations.CreateSanghSessions do
  use Ecto.Migration

  def change do

    create table(:sessions, primary_key: false) do
      add :id, :uuid, primary_key: true

      timestamps(type: :utc_datetime)
    end

    execute("CREATE EXTENSION ltree", "DROP EXTENSION ltree")

    create table(:comments, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :body, :text, null: false
      add :active, :boolean, default: false
      add :path, :ltree
      add :signature, :string
      add :session_id, references(:sessions, column: :id, type: :uuid)
      add :parent_id, references(:comments, column: :id, type: :uuid)

      timestamps(type: :utc_datetime_usec)
    end


    create table(:bindings, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :w_type, :string
      add :field_key, :string
      add :verse_id, references(:verses, column: :id, type: :uuid, on_delete: :nothing)
      add :chapter_no, references(:chapters, column: :no, type: :integer, with: [source_id: :source_id])
      add :translation_id, references(:translations, column: :id, type: :uuid, on_delete: :nothing)
      add :comment_id, references(:comments, column: :id, type: :uuid)
      add :comment_bind_id, references(:comments, column: :id, type: :uuid)
      add :source_id, references(:sources, column: :id, type: :uuid)
      add :window, :jsonb

      timestamps(type: :utc_datetime_usec)
    end

    create index(:comments, [:path])
    create index(:comments, [:session_id])
    create index(:bindings, [:chapter_no, :source_id])

  end
 end
