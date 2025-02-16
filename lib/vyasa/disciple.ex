defmodule Vyasa.Disciple do
  defstruct id: Ecto.UUID.generate(), name: "ॐ", action: "building", node: "@localhost", meta: nil
end
