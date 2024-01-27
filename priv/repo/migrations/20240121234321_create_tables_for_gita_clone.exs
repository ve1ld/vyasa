defmodule Vyasa.Repo.Migrations.CreateTablesForGitaClone do
  use Ecto.Migration

  def change do

    # this is probably just a temporary table for now
    create table(:sources, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
    end

    create table(:chapters, primary_key: false) do
      add :num, :integer, primary_key: true
      add :body, :string

      add :source_id,  references(:sources, column: :id, type: :uuid),  primary_key: true
    end

    create unique_index(:chapters, [:source_id, :num]) # (src) uniquely identifies a chapter, left chap out because it's optional

    create table(:verses, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :num, :integer
      add :body, :string

      add :source_id, references(:sources, column: :id, type: :uuid)
    end

    create unique_index(:verses, [:source_id, :num]) # (src) uniquely identifies a verse, left chap out because it's optional



    create table(:translations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :language, :string # might make sense to represent this in an enum table?
      add :body, :string
      add :meaning, :string # because translation's meaning and transliteration's meaning may differ

      ## QQ: unsure of a good choice of on-delete, putting nothing as default for now
      add :verse_id, references(:verses, column: :id, type: :uuid, on_delete: :nothing)
    end



    create table(:transliterations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :language, :string
      add :body, :string, null: false
      add :meaning, :string # meanings are specific to transliterations

      add :verse_id, references(:verses, column: :id, type: :uuid, on_delete: :nothing)
    end
  end
end
