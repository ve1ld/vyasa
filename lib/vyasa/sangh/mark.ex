defmodule Vyasa.Sangh.Mark do
  @moduledoc """
  Interpretation & bounding of binding
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Sangh.{Comment, Mark}
  alias Vyasa.Adapters.Binding
  alias Utils.Time

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "marks" do
    field :body, :string
    field :order, :integer

    # TODO: @ks0m1c these enums need better names or a docstring to explain why they are named like so
    field :state, Ecto.Enum, values: [:draft, :bookmark, :live]
    field :verse_id, :string, virtual: true

    belongs_to :comment, Comment, foreign_key: :comment_id, type: :binary_id
    belongs_to :binding, Binding, foreign_key: :binding_id, type: :binary_id

    timestamps()
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:body, :order, :status, :comment_id, :binding_id])
  end

  def update_mark(%Mark{} = draft_mark, opts \\ []) do
    draft_mark
    |> Map.merge(Map.new(opts))
    |> Time.maybe_insert_current_time(:inserted_at)
    |> Time.update_current_time(:updated_at)
  end
end
