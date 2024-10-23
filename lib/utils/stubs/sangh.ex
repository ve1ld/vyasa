defmodule Stubs.Vyasa.Sangh.Sheaf do
  alias Vyasa.Sangh.{Sheaf, Mark}

  def foo(attrs \\ %{}) do
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

  def get_dummy_sheaf(attrs \\ %{}) do
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

defmodule Stubs.Vyasa.Sangh.Mark do
  alias Vyasa.Sangh.{Mark}

  def get_dummy_mark(attrs \\ %{}) do
    %Mark{
      id: Ecto.UUID.generate(),
      order: 0,
      body: "Hey I'm a mark",
      state: :live
    }
    |> Map.merge(attrs)
    |> Mark.update_mark(%{})
  end
end
