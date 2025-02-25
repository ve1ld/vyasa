defmodule Vyasa.Repo.Migrations.CreateBhaj do
  use Ecto.Migration

  def change do

    create table(:tracklists, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string

      timestamps(type: :utc_datetime)
    end

    create table(:bhaj, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
      add :trackls_id, references(:tracklists, column: :id, type: :uuid, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:bhaj, [:trackls_id])
  end

  def up do
    alter table(:tracks) do
      remove :title
      add :order, :integer
      add :event_id, references(:events, column: :id, type: :uuid, on_delete: :nothing)
      add :trackls_id, references(:tracklists, column: :id, type: :uuid, on_delete: :delete_all)
    end


    create index(:tracks, [:trackls_id])
    create index(:tracks, [:event_id])

  end

  def down do
    alter table(:tracks) do
      add :title, :string
      remove :order, :integer
      remove :event_id, references(:events, column: :id, type: :uuid, on_delete: :nothing)
      remove :trackls_id, references(:tracklists, column: :id, type: :uuid, on_delete: :delete_all)
    end

    drop index(:tracks, [:trackls_id])
    drop index(:tracks, [:event_id])


  end
end
