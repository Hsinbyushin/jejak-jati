defmodule JejakJati.Workers.ResearchWorkerTest do
  use JejakJati.DataCase
  use Oban.Testing, repo: JejakJati.Repo

  alias JejakJati.Research
  alias JejakJati.Workers.ResearchWorker

  test "moves a research run from pending to review" do
    {:ok, research_run} =
      Research.create_research_run(%{
        title: "In Search of Modernity",
        author_name: "Hadijah Rahmat"
      })

    assert research_run.status == :pending

    assert :ok =
             perform_job(
               ResearchWorker,
               %{"research_run_id" => research_run.id}
             )

    updated_research_run =
      Research.get_research_run!(research_run.id)

    assert updated_research_run.status == :review
  end
end
