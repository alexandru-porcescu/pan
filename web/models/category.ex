defmodule Pan.Category do
  use Pan.Web, :model

  schema "categories" do
    field :title, :string
    belongs_to :parent, Pan.Parent
    many_to_many :podcasts, Pan.Podcast, join_through: "categories_podcasts"

    timestamps
  end

  @required_fields ~w(title)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end