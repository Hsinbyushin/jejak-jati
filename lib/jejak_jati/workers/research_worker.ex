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
    # Oban serializes job arguments as JSON. Consequently, argument keys
    # arrive as strings even if atoms were used when the job was created.
    #
    # We store only the ResearchRun ID in the job rather than copying the
    # title, author name, ISBN, or future research metadata into Oban.
    # The ResearchRun in our own database remains the source of truth.
    research_run = Research.get_research_run!(id)

    # Mark the research run as actively being processed.
    #
    # Later, the UI can use this state to tell the user that background
    # research is currently in progress.
    {:ok, research_run} =
      Research.update_research_run(research_run, %{status: :running})

    # ------------------------------------------------------------------
    # Research pipeline
    # ------------------------------------------------------------------
    #
    # This is intentionally empty for now.
    #
    # Future versions of this worker (or workers orchestrated by it) will
    # perform operations such as:
    #
    #   * searching bibliographic sources for the supplied publication,
    #   * searching authority files for possible person matches,
    #   * collecting source-backed evidence,
    #   * identifying conflicting claims,
    #   * ranking identity candidates,
    #   * preparing a proposed authority record for human review.
    #
    # Keeping this placeholder explicit makes an important architectural
    # distinction:
    #
    #   ResearchRun  -> represents the research request and its state
    #   Oban Job     -> represents reliable execution of background work
    #   Evidence     -> will represent facts discovered during research
    #
    # Those concepts should remain separate even as the application grows.

    # The infrastructure-only worker currently considers the automated
    # research phase complete immediately. It therefore moves the run into
    # `review`.
    #
    # `review` deliberately does not mean "completed". Jejak Jati is intended
    # to produce evidence-backed proposals that a human can inspect before
    # accepting an authority record.
    {:ok, _research_run} =
      Research.update_research_run(research_run, %{status: :review})

    # Returning :ok tells Oban that the job completed successfully.
    #
    # If an exception is raised above, or if we later return an error in a
    # form understood by Oban, Oban can record the failure and retry the job
    # according to the worker configuration.
    :ok
  end
end
