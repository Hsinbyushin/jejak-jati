defmodule JejakJati.Repo.Migrations.CreateResearchRuns do
  use Ecto.Migration

  def change do
    create table(:research_runs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :author_name, :string, null: false
      add :isbn, :string
      add :status, :string, null: false, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create index(:research_runs, [:status])
  end
end
