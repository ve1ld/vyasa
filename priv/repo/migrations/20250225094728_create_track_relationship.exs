defmodule Vyasa.Repo.Migrations.CreateTrackRelationship do
  use Ecto.Migration

  def up do
    alter table(:tracks) do
      remove :title
      add :order, :integer
      add :event_id, references(:events, column: :id, type: :uuid, on_delete: :nothing)
      add :trackls_id, references(:tracklists, column: :id, type: :uuid, on_delete: :delete_all)
    end




  end

  def down do
    alter table(:tracks) do
      add :title, :string
      remove :order, :integer
      remove :event_id, references(:events, column: :id, type: :uuid, on_delete: :nothing)
      remove :trackls_id, references(:tracklists, column: :id, type: :uuid, on_delete: :delete_all)
    end




  end

  def change do
        create index(:tracks, [:trackls_id])
      create index(:tracks, [:event_id])
      end
end
