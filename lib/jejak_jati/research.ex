defmodule JejakJati.Research do
  @moduledoc """
  The Research context.
  """

  import Ecto.Query, warn: false
  alias JejakJati.Repo

  alias JejakJati.Research.ResearchRun

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
  def create_research_run(attrs) do
    %ResearchRun{}
    |> ResearchRun.changeset(attrs)
    |> Repo.insert()
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
end
