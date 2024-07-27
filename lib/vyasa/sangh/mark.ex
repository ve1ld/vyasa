defmodule Vyasa.Sangh.Mark do
  @moduledoc """
  Interpretation & bounding of binding
  """

  use Ecto.Schema
   import Ecto.Changeset

   alias Vyasa.Sangh.{Comment}
   alias Vyasa.Adapters.Binding

   @primary_key {:id, Ecto.UUID, autogenerate: true}
   schema "marks" do
    field :body, :string
    field :order, :integer
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

end
