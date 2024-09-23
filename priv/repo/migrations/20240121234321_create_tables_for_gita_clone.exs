defmodule Vyasa.Repo.Migrations.CreateTablesForGitaClone do
  use Ecto.Migration

  def change do
    # this is probably just a temporary table for now
    create table(:sources, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
      add :lang, :string

      timestamps([:utc_datetime])
    end

    create table(:chapters, primary_key: false) do
      add :no, :integer, primary_key: true
      add :title, :string
      add :body, :text

      add :source_id, references(:sources, column: :id, type: :uuid), primary_key: true
    end

    # (src) uniquely identifies a chapter, left chap out because it's optional
    create unique_index(:chapters, [:source_id, :no])

    create table(:verses, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :no, :integer

      add :chapter_no,
          references(:chapters, column: :no, type: :integer, with: [source_id: :source_id])

      add :body, :text
      add :source_id, references(:sources, column: :id, type: :uuid), null: false
    end

    # (src) uniquely identifies a verse, left chap out because it's optional
    create unique_index(:verses, [:source_id, :chapter_no, :no])

    create table(:translations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :lang, :string
      add :type, :string

      add :target, :jsonb

      add :chapter_no,
          references(:chapters, column: :no, type: :integer, with: [source_id: :source_id])

      add :verse_id, references(:verses, column: :id, type: :uuid, on_delete: :nothing)
      add :source_id, references(:sources, column: :id, type: :uuid), null: false
    end
  end
end
