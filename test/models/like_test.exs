defmodule Pan.LikeTest do
  use Pan.ModelCase

  alias PanWeb.Like

  @valid_attrs %{comment: "Like comment"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    enjoyer = insert_user()
    podcast = insert_podcast()
    changeset = Like.changeset(%Like{},
                               Map.merge(@valid_attrs, %{enjoyer_id: enjoyer.id,
                                                         podcast_id: podcast.id}))
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Like.changeset(%Like{}, @invalid_attrs)
    refute changeset.valid?
  end
end
