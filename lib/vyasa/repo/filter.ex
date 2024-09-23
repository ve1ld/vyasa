defmodule Vyasa.Repo.Filter do
  import Ecto.Query

  defmacrop custom_where(binding, field, val, operator) do
    {operator, [context: Elixir, import: Kernel],
     [
       {:field, [], [binding, {:^, [], [field]}]},
       {:^, [], [val]}
     ]}
  end

  for op <- [:!=, :<, :<=, :==, :>, :>=, :ilike, :in, :like] do
    def where(query, {as, field}, unquote(op), value) do
      query
      |> where([{^as, x}], custom_where(x, field, value, unquote(op)))
    end

    def where(query, field_name, unquote(op), value) do
      query
      |> where([o], custom_where(o, field_name, value, unquote(op)))
    end
  end
end
