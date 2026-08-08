defmodule JejakJati.ResearchTest do
  use JejakJati.DataCase

  use Oban.Testing, repo: JejakJati.Repo

  alias JejakJati.Research

  describe "research_runs" do
    alias JejakJati.Research.ResearchRun

    import JejakJati.ResearchFixtures

    @invalid_attrs %{status: nil, title: nil, author_name: nil, isbn: nil}

    test "list_research_runs/0 returns all research_runs" do
      research_run = research_run_fixture()
      assert Research.list_research_runs() == [research_run]
    end

    test "get_research_run!/1 returns the research_run with given id" do
      research_run = research_run_fixture()
      assert Research.get_research_run!(research_run.id) == research_run
    end

    test "create_research_run/1 with valid data creates a research_run" do
      valid_attrs = %{
        status: :pending,
        title: "some title",
        author_name: "some author_name",
        isbn: "some isbn"
      }

      assert {:ok, %ResearchRun{} = research_run} = Research.create_research_run(valid_attrs)
      assert research_run.status == :pending
      assert research_run.title == "some title"
      assert research_run.author_name == "some author_name"
      assert research_run.isbn == "some isbn"
    end

    test "create_research_run/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Research.create_research_run(@invalid_attrs)
    end

    test "update_research_run/2 with valid data updates the research_run" do
      research_run = research_run_fixture()

      update_attrs = %{
        status: :running,
        title: "some updated title",
        author_name: "some updated author_name",
        isbn: "some updated isbn"
      }

      assert {:ok, %ResearchRun{} = research_run} =
               Research.update_research_run(research_run, update_attrs)

      assert research_run.status == :running
      assert research_run.title == "some updated title"
      assert research_run.author_name == "some updated author_name"
      assert research_run.isbn == "some updated isbn"
    end

    test "update_research_run/2 with invalid data returns error changeset" do
      research_run = research_run_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Research.update_research_run(research_run, @invalid_attrs)

      assert research_run == Research.get_research_run!(research_run.id)
    end

    test "delete_research_run/1 deletes the research_run" do
      research_run = research_run_fixture()
      assert {:ok, %ResearchRun{}} = Research.delete_research_run(research_run)
      assert_raise Ecto.NoResultsError, fn -> Research.get_research_run!(research_run.id) end
    end

    test "change_research_run/1 returns a research_run changeset" do
      research_run = research_run_fixture()
      assert %Ecto.Changeset{} = Research.change_research_run(research_run)
    end

    test "create_research_run/1 enqueues a research job" do
      assert {:ok, research_run} =
               Research.create_research_run(%{
                 title: "In Search of Modernity",
                 author_name: "Hadijah Rahmat"
               })

      assert_enqueued(
        worker: JejakJati.Workers.ResearchWorker,
        args: %{"research_run_id" => research_run.id}
      )

      assert research_run.person_id

      person = Research.get_person!(research_run.person_id)

      assert person.preferred_name == "Hadijah Rahmat"
    end
  end

  describe "people" do
    test "creates a person" do
      assert {:ok, person} =
               Research.create_person(%{
                 preferred_name: "Hadijah Rahmat",
                 birth_year: 1958
               })

      assert person.preferred_name == "Hadijah Rahmat"
      assert person.birth_year == 1958
      assert person.death_year == nil
    end

    test "requires a preferred name" do
      assert {:error, changeset} =
               Research.create_person(%{})

      assert "can't be blank" in errors_on(changeset).preferred_name
    end

    test "rejects a death year earlier than the birth year" do
      assert {:error, changeset} =
               Research.create_person(%{
                 preferred_name: "Example Person",
                 birth_year: 1980,
                 death_year: 1970
               })

      assert "must not be earlier than birth year" in errors_on(changeset).death_year
    end
  end
end
