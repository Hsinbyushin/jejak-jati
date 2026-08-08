defmodule JejakJati.Workers.ResearchWorkerTest do
  use JejakJati.DataCase
  use Oban.Testing, repo: JejakJati.Repo

  alias JejakJati.Research
  alias JejakJati.Sources.DNB
  alias JejakJati.Sources.OpenLibrary
  alias JejakJati.Workers.ResearchWorker

  setup do
    Req.Test.verify_on_exit!()

    dnb_xml =
      File.read!("test/fixtures/dnb/search_response.xml")

    open_library_body =
      "test/fixtures/open_library/search_response.json"
      |> File.read!()
      |> Jason.decode!()

    Req.Test.stub(DNB, fn conn ->
      Req.Test.text(conn, dnb_xml)
    end)

    Req.Test.stub(OpenLibrary, fn conn ->
      Req.Test.json(conn, open_library_body)
    end)

    :ok
  end

  test "moves a research run from pending to review" do
    {:ok, research_run} =
      Research.create_research_run(%{
        title: "In Search of Modernity",
        author_name: "Hadijah Rahmat",
        isbn: "9789832085010"
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

    source_requests =
      Research.list_source_requests_for_run(research_run.id)

    assert length(source_requests) == 2

    dnb_request =
      Enum.find(source_requests, &(&1.source == :dnb))

    open_library_request =
      Enum.find(source_requests, &(&1.source == :open_library))

    assert dnb_request
    assert open_library_request

    assert dnb_request.status == :succeeded
    assert dnb_request.candidate_count == 1
    assert dnb_request.best_score == 200
    assert dnb_request.decision == :strong_match
    assert dnb_request.error_message == nil

    [dnb_candidate] = dnb_request.source_candidates

    assert dnb_candidate.source_id == "123456789"
    assert dnb_candidate.title == "In Search of Modernity"
    assert dnb_candidate.author_name == "Rahmat, Hadijah"
    assert dnb_candidate.isbn == "9789832085010"
    assert dnb_candidate.publication_year == "2001"
    assert dnb_candidate.publisher == "University of Malaya Press"
    assert dnb_candidate.source_url == "https://d-nb.info/123456789"

    assert dnb_candidate.score == 200
    assert dnb_candidate.match_reasons["title_exact"] == 60
    assert dnb_candidate.match_reasons["author_exact"] == 40
    assert dnb_candidate.match_reasons["isbn_exact"] == 100

    assert open_library_request.status == :succeeded
    assert open_library_request.candidate_count == 1
    assert open_library_request.best_score == 200
    assert open_library_request.decision == :strong_match
    assert open_library_request.error_message == nil

    [open_library_candidate] =
      open_library_request.source_candidates

    assert open_library_candidate.source_id == "OL123456W"
    assert open_library_candidate.title == "In Search of Modernity"
    assert open_library_candidate.author_name == "Hadijah Rahmat"
    assert open_library_candidate.isbn == "9789832085010"
    assert open_library_candidate.publication_year == "2001"
    assert open_library_candidate.publisher == "University of Malaya Press"

    assert open_library_candidate.source_url ==
             "https://openlibrary.org/works/OL123456W"

    assert open_library_candidate.score == 200
    assert open_library_candidate.match_reasons["title_exact"] == 60
    assert open_library_candidate.match_reasons["author_exact"] == 40
    assert open_library_candidate.match_reasons["isbn_exact"] == 100

    reconciliations =
      Research.list_work_reconciliations_for_run(research_run.id)

    assert length(reconciliations) == 1

    [reconciliation] = reconciliations

    assert reconciliation.decision == :same_work
    assert reconciliation.score == 210
    assert reconciliation.reasons["isbn_exact"] == 100
    assert reconciliation.reasons["title_exact"] == 60
    assert reconciliation.reasons["author_exact"] == 40
    assert reconciliation.reasons["publication_year_exact"] == 10
  end
end
