defmodule Vyasa.Sangh.Mark do
  @moduledoc """
  Interpretation & bounding of binding.
  We can mark anything that we can create a binding for.

  A mark should be seen as a single interpretation of a binding.
  example: for text X, verse Y, we can have many marks, each offerring their own interpretation of Y.
  An analogy for it would be "we left a mark on something...".
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Vyasa.Sangh.{Sheaf, Mark}
  alias Vyasa.Adapters.Binding
  alias Utils.Time

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "marks" do
    field :body, :string
    field :order, :integer

    # TODO: @ks0m1c these enums need better names or a docstring to explain why they are named like so
    field :state, Ecto.Enum, values: [:draft, :bookmark, :live]
    field :verse_id, :string, virtual: true

    belongs_to :sheaf, Sheaf, foreign_key: :sheaf_id, type: :binary_id
    belongs_to :binding, Binding, foreign_key: :binding_id, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:id, :body, :order, :state, :sheaf_id, :binding_id, :updated_at, :inserted_at])
  end

  def update_mark(%Mark{} = draft_mark, opts \\ %{}) do
    draft_mark
    |> Map.merge(Map.new(opts))
    |> Time.maybe_insert_current_time(:inserted_at)
    |> Time.update_current_time(:updated_at)
  end

  def get_draft_mark(marks \\ nil, opts \\ %{}) do
    %Mark{
      id: Ecto.UUID.generate(),
      state: :draft,
      order: get_next_order(marks)
    }
    |> Map.merge(opts)
  end

  def get_next_order(marks) when is_list(marks) do
    1 +
      (marks
       |> Enum.map(& &1.order)
       |> Enum.max(&>=/2, fn -> 0 end))
  end

  def get_next_order(_) do
    1
  end
end
