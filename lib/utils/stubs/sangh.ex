defmodule Stubs.Vyasa.Sangh.Sheaf do
  alias Vyasa.Sangh.Sheaf

  def foo(attrs \\ {}) do
    %Sheaf{
      id: Ecto.UUID.generate(),
      session_id: Ecto.UUID.generate(),
      body:
        "Hey, so this is my sheaf, I have something important to say\n what do you think about it?",
      signature: "Ritesh Kumar",
      traits: ["draft"]
    }
    |> Map.merge(attrs)
  end

  def get_dummy_sheaf(attrs \\ {}) do
    %Sheaf{
      id: Ecto.UUID.generate(),
      session_id: Ecto.UUID.generate(),
      body:
        "Hey, so this is my sheaf, I have something important to say\n what do you think about it?",
      signature: "Ritesh Kumar",
      traits: ["draft"]
    }
    |> Map.merge(attrs)
  end
end
