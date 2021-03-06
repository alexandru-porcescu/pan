defmodule Pan.RecommendationTest do
  use Pan.ModelCase

  alias PanWeb.Recommendation

  @valid_attrs %{comment: "Recommendation comment"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Recommendation.changeset(%Recommendation{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Recommendation.changeset(%Recommendation{}, @invalid_attrs)
    refute changeset.valid?
  end
end
