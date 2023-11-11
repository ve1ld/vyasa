defmodule Vyasa.Repo do
  use Ecto.Repo,
    otp_app: :vyasa,
    adapter: Ecto.Adapters.Postgres
end
