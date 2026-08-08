defmodule JejakJati.Workers.ResearchWorker do
  alias JejakJati.Bibliography.WorkMatcher
  alias JejakJati.Research
  alias JejakJati.Sources.Orchestrator
  alias JejakJati.Reconciliation.WorkReconciler

  @moduledoc """
  Executes the background research workflow for a single research run.

  A research run represents a user request to investigate an author in the
  context of a particular publication. The ResearchWorker performs the
  asynchronous work associated with that request.

  The worker receives only the ID of the research run. The actual research
  data is loaded from the database when the job starts. This keeps Oban jobs
  small and ensures that the database remains the authoritative source for
  the current state of a research run.

  At this early stage of Jejak Jati, the worker only demonstrates the
  lifecycle of a research job:

      pending -> running -> review

  Actual source research (for example DNB, Wikidata, VIAF, or other authority
  and bibliographic sources) will be inserted between the `running` and
  `review` transitions later.
  """

  use Oban.Worker,
    # Jobs created by this worker are placed in the dedicated `research`
    # queue. The queue and its concurrency limit are configured in
    # config/config.exs.
    queue: :research,

    # Oban may retry a job when it fails. Limiting the number of attempts
    # prevents a permanently failing research job from being retried
    # indefinitely.
    max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"research_run_id" => id}}) do
    research_run = Research.get_research_run!(id)

    {:ok, research_run} =
      Research.update_research_run(research_run, %{status: :running})

    :ok = run_bibliographic_research(research_run)

    {:ok, _research_run} =
      Research.update_research_run(research_run, %{status: :review})

    :ok
  end

  defp run_bibliographic_research(research_run) do
    research_run
    |> Orchestrator.search()
    |> Enum.each(fn source_result ->
      process_source_result(research_run, source_result)
    end)

    source_requests =
      Research.list_source_requests_for_run(research_run.id)

    reconciliations =
      source_requests
      |> WorkReconciler.reconcile()
      |> Enum.filter(&WorkReconciler.relevant?/1)

    Enum.each(reconciliations, fn reconciliation ->
      reasons =
        Map.new(reconciliation.reasons, fn {reason, points} ->
          {Atom.to_string(reason), points}
        end)

      {:ok, _work_reconciliation} =
        Research.create_work_reconciliation(%{
          left_candidate_id: reconciliation.left.id,
          right_candidate_id: reconciliation.right.id,
          score: reconciliation.score,
          decision: reconciliation.decision,
          reasons: reasons
        })
    end)

    :ok
  end

  defp process_source_result(
         research_run,
         %{source: source, result: {:ok, candidates}}
       ) do
    {:ok, source_request} =
      Research.create_source_request(%{
        research_run_id: research_run.id,
        source: source,
        status: :running
      })

    ranked =
      WorkMatcher.rank(
        candidates,
        %{
          title: research_run.title,
          author_name: research_run.author_name,
          isbn: research_run.isbn
        }
      )

    Enum.each(ranked, fn match ->
      persist_candidate(source_request, match)
    end)

    decision = WorkMatcher.classify(ranked)

    best_score =
      case ranked do
        [%{score: score} | _] -> score
        [] -> nil
      end

    {:ok, _source_request} =
      Research.update_source_request(source_request, %{
        status: :succeeded,
        candidate_count: length(candidates),
        best_score: best_score,
        decision: decision
      })

    :ok
  end

  defp process_source_result(
         research_run,
         %{source: source, result: {:error, reason}}
       ) do
    {:ok, _source_request} =
      Research.create_source_request(%{
        research_run_id: research_run.id,
        source: source,
        status: :failed,
        candidate_count: 0,
        error_message: inspect(reason)
      })

    :ok
  end

  defp persist_candidate(source_request, match) do
    result = match.result

    match_reasons =
      Map.new(match.reasons, fn {reason, points} ->
        {Atom.to_string(reason), points}
      end)

    {:ok, _source_candidate} =
      Research.create_source_candidate(%{
        source_request_id: source_request.id,
        source_id: result.source_id,
        title: result.title,
        author_name: result.author_name,
        isbn: result.isbn,
        publication_year: result.publication_year,
        publisher: result.publisher,
        source_url: result.source_url,
        score: match.score,
        match_reasons: match_reasons
      })

    :ok
  end
end
