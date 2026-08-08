defmodule JejakJati.Repo.Migrations.AddPersonToResearchRuns do
  use Ecto.Migration

  def change do
    alter table(:research_runs) do
      add :person_id,
          references(:people,
            type: :binary_id,
            on_delete: :nilify_all
          )
    end

    create index(:research_runs, [:person_id])
  end
end
