defmodule Vyasa.Repo.Migrations.CreateSanghSessions do
  use Ecto.Migration

  def change do

    create unique_index(:texts, [:title], name: :unique_titles)

    create table(:sessions, primary_key: false) do
      add :id, :uuid, primary_key: true

      timestamps(type: :utc_datetime)
    end

    execute("CREATE EXTENSION ltree", "DROP EXTENSION ltree")

    create table(:comments, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :active, :boolean, default: false
      add :body, :text, null: false
      add :p_type, :string
      add :path, :ltree
      add :session_id, references(:sessions, column: :id, type: :uuid)
      add :text_title, references(:texts, column: :title, type: :string)
      add :chapter_number, :integer
      add :pointer, :jsonb
      add :parent_id, references(:comments, column: :id, type: :uuid)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:comments, [:path])
    create index(:comments, [:text_title, :session_id, :chapter_number])

  end
 end
