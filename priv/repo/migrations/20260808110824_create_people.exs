defmodule JejakJati.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :preferred_name, :string, null: false
      add :birth_year, :integer
      add :death_year, :integer

      timestamps(type: :utc_datetime)
    end

    create index(:people, [:preferred_name])
  end
end
