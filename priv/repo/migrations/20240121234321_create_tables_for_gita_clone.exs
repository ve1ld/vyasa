defmodule Vyasa.Repo.Migrations.CreateTablesForGitaClone do
  use Ecto.Migration

  def change do

    # this is probably just a temporary table for now
    create table(:sources, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string

      timestamps([:utc_datetime])
    end

    create table(:chapters, primary_key: false) do
      add :no, :integer, primary_key: true
      add :title, :string
      add :body, :text
      add :indic_name, :text
      add :indic_name_meaning, :text
      add :indic_summary, :text
      add :indic_name_translation, :text
      add :indic_name_transliteration, :text

      add :source_id,  references(:sources, column: :id, type: :uuid),  primary_key: true
    end

    create unique_index(:chapters, [:source_id, :no]) # (src) uniquely identifies a chapter, left chap out because it's optional

    create table(:verses, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :no, :integer
      add :chapter_no, references(:chapters, column: :no, type: :integer, with: [source_id: :source_id])
      add :body, :text
      add :source_id, references(:sources, column: :id, type: :uuid), null: false
    end

    create unique_index(:verses, [:source_id, :chapter_no, :no]) # (src) uniquely identifies a verse, left chap out because it's optional



    create table(:translations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :lang, :string # might make sense to represent this in an enum table?
      add :body, :string
      add :meaning, :string # because translation's meaning and transliteration's meaning may differ

      ## QQ: unsure of a good choice of on-delete, putting nothing as default for now
      add :verse_id, references(:verses, column: :id, type: :uuid, on_delete: :nothing)
    end



    create table(:transliterations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :lang, :string
      add :body, :string, null: false
      add :meaning, :string # meanings are specific to transliterations

      add :verse_id, references(:verses, column: :id, type: :uuid, on_delete: :nothing)
    end
  end
end
