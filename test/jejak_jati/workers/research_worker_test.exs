defmodule JejakJati.Workers.ResearchWorkerTest do
  use JejakJati.DataCase
  use Oban.Testing, repo: JejakJati.Repo

  alias JejakJati.Research
  alias JejakJati.Sources.DNB
  alias JejakJati.Workers.ResearchWorker

  setup do
    Req.Test.verify_on_exit!()

    xml =
      File.read!("test/fixtures/dnb/search_response.xml")

    Req.Test.stub(DNB, fn conn ->
      Req.Test.text(conn, xml)
    end)

    :ok
  end

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

    [source_request] =
      Research.list_source_requests_for_run(research_run.id)

    assert source_request.source == :dnb
    assert source_request.status == :succeeded
    assert source_request.candidate_count == 1
    assert source_request.decision == :strong_match
    assert source_request.best_score >= 100
    assert source_request.error_message == nil
  end
end
