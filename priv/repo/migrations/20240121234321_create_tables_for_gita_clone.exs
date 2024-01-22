defmodule Vyasa.Repo.Migrations.CreateTablesForGitaClone do
  use Ecto.Migration

  def change do

    # this is probably just a temporary table for now
    create table(:sources) do
      add :title, :string
    end


    create table(:verses, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :chapter_num, :integer# , default: 0
      # for sources that don't have any chapters
      add :verse_num, :integer
      add :verse_text, :string

      add :source_id, references(:sources)
    end



    # ################################################################################################
    # # @doc"""                                                                                      #
    # # Translations are assoc to verses in a belongs_to r/s and shall show alternative verse_texts. #
    # # This intends to support different languages.                                                 #
    # # """                                                                                          #
    # ################################################################################################
    create table(:translations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :language, :string # might make sense to represent this in an enum table?
      add :verse_text, :string

      add :verse_id, references(:verses, column: :id, type: :uuid, on_delete: :nothing)
    end

    create unique_index(:translations, [:verse_id]) # each translation only has one associated verse


    # # ####################################################################################################
    # # # @doc"""                                                                                          #
    # # # Transliterations are assoc to verses in a belongs_to r/s and shall show alternative verse_texts. #
    # # # This intends to support different languages.                                                     #
    # # # """                                                                                              #
    # # ####################################################################################################
    create table(:transliterations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :language, :string
      add :transliteration_text, :string, null: false

      add :verse_id, references(:verses, column: :id, type: :uuid, on_delete: :nothing)
    end

    create unique_index(:transliterations, [:verse_id]) # each translation only has one associated verse

    # ##################################
    # # @doc"""                        #
    # # Transcripts are a TODO for now #
    # # """                            #
    # ##################################
    create table(:transcripts, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :verse_id, references(:verses, column: :id, type: :uuid, on_delete: :nothing)
    end

    create unique_index(:transcripts, [:verse_id]) # each translation only has one associated verse


    # ###########
    # # @doc""" #
    # # """     #
    # ###########
    create table(:media, primary_key: false) do
      add :id, :uuid, primary_key: true
    end

  end
end
