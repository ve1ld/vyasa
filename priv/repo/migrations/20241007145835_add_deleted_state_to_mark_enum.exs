defmodule Vyasa.Repo.Migrations.AddDeletedStateToMarkEnum do
  use Ecto.Migration

  # NOTE: migration file before this had not created the enum and had left it as a string
  def up do
    execute "CREATE TYPE marks_state_enum AS ENUM ('draft', 'bookmark', 'live', 'deleted')"
  end

  def down do
    execute "DROP TYPE marks_state_enum"
  end
end
