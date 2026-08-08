defmodule JejakJati.Research do
  @moduledoc """
  The Research context.
  """

  import Ecto.Query, warn: false
  alias JejakJati.Repo

  alias JejakJati.Research.ResearchRun
  alias JejakJati.Research.SourceRequest
  alias JejakJati.Research.SourceCandidate
  alias JejakJati.Research.WorkReconciliation
  alias JejakJati.Research.Person

  @doc """
  Returns the list of research_runs.

  ## Examples

      iex> list_research_runs()
      [%ResearchRun{}, ...]

  """
  def list_research_runs do
    Repo.all(ResearchRun)
  end

  @doc """
  Gets a single research_run.

  Raises `Ecto.NoResultsError` if the Research run does not exist.

  ## Examples

      iex> get_research_run!(123)
      %ResearchRun{}

      iex> get_research_run!(456)
      ** (Ecto.NoResultsError)

  """
  def get_research_run!(id), do: Repo.get!(ResearchRun, id)

  @doc """
  Creates a research_run.

  ## Examples

      iex> create_research_run(%{field: value})
      {:ok, %ResearchRun{}}

      iex> create_research_run(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_research_run(attrs \\ %{}) do
    %ResearchRun{}
    |> ResearchRun.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, research_run} ->
        %{research_run_id: research_run.id}
        |> JejakJati.Workers.ResearchWorker.new()
        |> Oban.insert()

        {:ok, research_run}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a research_run.

  ## Examples

      iex> update_research_run(research_run, %{field: new_value})
      {:ok, %ResearchRun{}}

      iex> update_research_run(research_run, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_research_run(%ResearchRun{} = research_run, attrs) do
    research_run
    |> ResearchRun.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a research_run.

  ## Examples

      iex> delete_research_run(research_run)
      {:ok, %ResearchRun{}}

      iex> delete_research_run(research_run)
      {:error, %Ecto.Changeset{}}

  """
  def delete_research_run(%ResearchRun{} = research_run) do
    Repo.delete(research_run)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking research_run changes.

  ## Examples

      iex> change_research_run(research_run)
      %Ecto.Changeset{data: %ResearchRun{}}

  """
  def change_research_run(%ResearchRun{} = research_run, attrs \\ %{}) do
    ResearchRun.changeset(research_run, attrs)
  end

  def create_source_request(attrs) do
    %SourceRequest{}
    |> SourceRequest.changeset(attrs)
    |> Repo.insert()
  end

  def update_source_request(%SourceRequest{} = source_request, attrs) do
    source_request
    |> SourceRequest.changeset(attrs)
    |> Repo.update()
  end

  def get_source_request!(id) do
    Repo.get!(SourceRequest, id)
  end

  def list_source_requests_for_run(research_run_id) do
    import Ecto.Query

    SourceRequest
    |> where([request], request.research_run_id == ^research_run_id)
    |> order_by([request], asc: request.inserted_at)
    |> preload([request],
      source_candidates:
        ^from(candidate in SourceCandidate,
          order_by: [desc: candidate.score]
        )
    )
    |> Repo.all()
  end

  def create_source_candidate(attrs) do
    %SourceCandidate{}
    |> SourceCandidate.changeset(attrs)
    |> Repo.insert()
  end

  def list_source_candidates_for_request(source_request_id) do
    import Ecto.Query

    SourceCandidate
    |> where([candidate], candidate.source_request_id == ^source_request_id)
    |> order_by([candidate], desc: candidate.score)
    |> Repo.all()
  end

  def create_work_reconciliation(attrs \\ %{}) do
    %WorkReconciliation{}
    |> WorkReconciliation.changeset(attrs)
    |> Repo.insert()
  end

  def list_work_reconciliations_for_run(research_run_id) do
    from(wr in WorkReconciliation,
      join: left in assoc(wr, :left_candidate),
      join: left_request in assoc(left, :source_request),
      where: left_request.research_run_id == ^research_run_id,
      order_by: [desc: wr.score],
      preload: [
        left_candidate: :source_request,
        right_candidate: :source_request
      ]
    )
    |> Repo.all()
  end

  def create_person(attrs \\ %{}) do
    %Person{}
    |> Person.changeset(attrs)
    |> Repo.insert()
  end

  def get_person!(id) do
    Repo.get!(Person, id)
  end

  def list_people do
    Repo.all(Person)
  end
end
