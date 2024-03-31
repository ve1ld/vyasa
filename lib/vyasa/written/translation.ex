defmodule Vyasa.Written.Translation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Vyasa.Written.{Verse, Chapter, Source}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "translations" do
    field :lang, :string
    # target table
    field :type, :string
    #polymorphic shape of target
    embeds_one :target, Target, on_replace: :delete do
      # for chapter
      field(:title, :string)
      field(:translit_title, :string)
      # for chapter/verse
      field(:body, :string)
      field(:body_meant, :string)
      field(:body_translit, :string)
      # for verse lexical fragments
      field(:body_translit_meant, :string)
      # media
    end


    belongs_to :verse, Verse, references: :id, type: Ecto.UUID
    belongs_to :chapter, Chapter, references: :no, foreign_key: :chapter_no, type: :integer
    belongs_to :source, Source, references: :id, type: Ecto.UUID
  end

  # TODO: [low-priority].
  # Once the schema aspects are more or less standardised, there's value in creating a default
  # changeset / changeset that gets fired by the parent entity such that we can pass in a single
  # map and that will do the db seeding, as opposed to the 3-step seeding approach that is being
  # done now.


  @doc false
  def changeset(translation, %{"type" => type} = attrs) do
    # %{translation | type: type, verse_id: verse_id, source_id: s_id, chap_no: } # <== DON'T DO THIS. this will create extra associations to chap, but in this fn we only want verse-assocs
    translation
    |> cast(attrs, [:lang, :type, :verse_id, :chapter_no, :source_id])
    |> typed_target_switch(type)
    |> validate_required([:lang])
  end

  def gen_changeset(translation, attrs, %Verse{id: verse_id, __meta__: %{source: type}, source_id: s_id}) do
    # %{translation | type: type, verse_id: verse_id, source_id: s_id, chap_no: } # <== DON'T DO THIS. this will create extra associations to chap, but in this fn we only want verse-assocs
    %{translation | type: type, verse_id: verse_id, source_id: s_id}
    |> cast(attrs, [:lang])
    |> typed_target_switch(type)
    |> validate_required([:lang])
  end

  def gen_changeset(translation, attrs, %Chapter{no: c_no, __meta__: %{source: type}, source_id: s_id}) do
    %{translation | type: type, chapter_no: c_no, source_id: s_id}
    |> cast(attrs, [:lang])
    |> typed_target_switch(type)
    |> validate_required([:lang])
    |> validate_inclusion(:lang, ["en", "or", "sa", "hi", "mr", "ta", "ml", "ka"])
    |> foreign_key_constraint(:s_id)
  end


  def gen_changeset(translation, attrs, _parent) do
    translation
    |> cast(attrs, [:lang, :body])
    |> validate_inclusion(:type, ["verses", "chapters"])
  end

  def typed_target_switch(changeset, type) when type in ["chapters", "verses"] do
    #changeset |> validate_inclusion(:type, ["chapters", "verses"])
    target_changeset = case type do
                            "chapters" ->
                              &chapter_changeset(&1, &2)
                            "verses" ->
                              &verse_changeset(&1, &2)
                          end

    cast_embed(changeset, :target, with: target_changeset)
  end

  def typed_target_switch(changeset, _attrs), do: validate_required(changeset, [:type])

  def chapter_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:title, :translit_title, :body, :body_translit])
  end

  def verse_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:body, :body_meant ,:body_translit, :body_translit_meant])
  end
end
