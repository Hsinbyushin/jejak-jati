defmodule JejakJati.Workers.ResearchWorker do
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

  alias JejakJati.Research

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"research_run_id" => id}}) do
    research_run = Research.get_research_run!(id)

    {:ok, research_run} =
      Research.update_research_run(research_run, %{status: :running})

    {:ok, source_request} =
      Research.create_source_request(%{
        research_run_id: research_run.id,
        source: :dnb,
        status: :running
      })

    run_dnb_research(research_run, source_request)
  end

  defp run_dnb_research(research_run, source_request) do
    alias JejakJati.Bibliography.WorkMatcher
    alias JejakJati.Sources.DNB

    case DNB.search_work(
           research_run.title,
           research_run.author_name
         ) do
      {:ok, candidates} ->
        ranked =
          WorkMatcher.rank(
            candidates,
            %{
              title: research_run.title,
              author_name: research_run.author_name,
              isbn: research_run.isbn
            }
          )

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

        {:ok, _research_run} =
          Research.update_research_run(research_run, %{
            status: :review
          })

        :ok

      {:error, reason} ->
        {:ok, _source_request} =
          Research.update_source_request(source_request, %{
            status: :failed,
            error_message: inspect(reason)
          })

        {:ok, _research_run} =
          Research.update_research_run(research_run, %{
            status: :failed
          })

        {:error, reason}
    end
  end
end
