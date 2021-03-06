defmodule PanWeb.PersonaController do
  use Pan.Web, :controller
  alias PanWeb.Persona

  def index(conn, _params) do
    render(conn, "index.html")
  end


  def datatable(conn, params) do
    search = params["search"]["value"]
    searchfrag = "%#{params["search"]["value"]}%"

    limit = String.to_integer(params["length"])
    offset = String.to_integer(params["start"])
    draw = String.to_integer(params["draw"])

    columns = params["columns"]

    order_by = Enum.map(params["order"], fn({_key, value}) ->
                 column_number = value["column"]
                 {String.to_atom(value["dir"]), String.to_atom(columns[column_number]["data"])}
               end)

    records_total = Repo.aggregate(Persona, :count, :id)

    query =
      if search != "" do
        from(p in Persona, where: ilike(p.pid, ^searchfrag) or
                                  ilike(p.name, ^searchfrag) or
                                  ilike(p.uri, ^searchfrag) or
                                  ilike(p.email, ^searchfrag) or
                                  ilike(p.image_title, ^searchfrag) or
                                  ilike(fragment("cast (? as text)", p.id), ^searchfrag))
      else
        from(p in Persona)
      end

    records_filtered = query
                       |> Repo.aggregate(:count, :id)

    personas = from(p in query, limit: ^limit,
                                offset: ^offset,
                                order_by: ^order_by)
               |> Repo.all()

    render(conn, "datatable.json", personas: personas,
                                   draw: draw,
                                   records_total: records_total,
                                   records_filtered: records_filtered)
  end


  def new(conn, _params) do
    changeset = Persona.changeset(%Persona{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"persona" => persona_params}) do
    changeset = Persona.changeset(%Persona{}, persona_params)

    case Repo.insert(changeset) do
      {:ok, _persona} ->
        conn
        |> put_flash(:info, "Persona created successfully.")
        |> redirect(to: persona_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def show(conn, %{"id" => id}) do
    persona = Repo.get!(Persona, id)
    render(conn, "show.html", persona: persona)
  end


  def edit(conn, %{"id" => id}) do
    persona = Repo.get!(Persona, id)
    changeset = Persona.changeset(persona)
    render(conn, "edit.html", persona: persona, changeset: changeset)
  end


  def update(conn, %{"id" => id, "persona" => persona_params}) do
    id = String.to_integer(id)
    persona = Repo.get!(Persona, id)
    changeset = Persona.changeset(persona, persona_params)

    case Repo.update(changeset) do
      {:ok, persona} ->
        Persona.update_search_index(id)

        conn
        |> put_flash(:info, "Persona updated successfully.")
        |> redirect(to: persona_path(conn, :show, persona))
      {:error, changeset} ->
        render(conn, "edit.html", persona: persona, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    id = String.to_integer(id)
    persona = Repo.get!(Persona, id)

    Repo.delete!(persona)
    Persona.delete_search_index(id)

    conn
    |> put_flash(:info, "Persona deleted successfully.")
    |> redirect(to: persona_path(conn, :index))
  end


  def merge_candidates(conn, _params) do
    non_unique_names = from(p in Persona, group_by: p.name,
                                          having: count(p.id) > 1,
                                          select: {p.name, count(p.id)},
                                          order_by: p.name)
                       |> Repo.all()

    non_unique_emails = from(p in Persona, group_by: p.email,
                                           having: count(p.id) > 1,
                                           select: {p.email, count(p.id)},
                                           order_by: p.email)
                        |> Repo.all()

    render(conn, "merge_candidates.html", non_unique_names: non_unique_names,
                                          non_unique_emails: non_unique_emails)
  end


  def merge_candidate_group(conn, %{"name" => name}) do
    personas = from(p in Persona, where: p.name == ^name,
                                  preload: [:engagements, :gigs])
               |> Repo.all()

    render(conn, "merge_candidate_group.html", personas: personas)
  end


  def merge_candidate_group(conn, %{"email" => email}) do
    personas = from(p in Persona, where: p.email == ^email,
                                  preload: [:engagements, :gigs])
               |> Repo.all()

    render(conn, "merge_candidate_group.html", personas: personas)
  end


  def merge(conn, %{"from" => from, "to" => to}) do
    from_id = String.to_integer(from)
    to_id   = String.to_integer(to)

    engagements = from(e in PanWeb.Engagement, where: e.persona_id == ^from_id)
                  |> Repo.all()

    for engagement <- engagements do
      case Repo.get_by(PanWeb.Engagement, persona_id: to_id,
                                       podcast_id: engagement.podcast_id,
                                       role: engagement.role) do
        nil ->
          PanWeb.Engagement.changeset(engagement, %{persona_id: to_id})
          |> Repo.update()
        _ ->
          Repo.delete!(engagement)
      end
    end

    from(g in PanWeb.Gig, where: g.persona_id == ^from_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(l in PanWeb.Like, where: l.persona_id == ^from_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(f in PanWeb.Follow, where: f.persona_id == ^from_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(p in Persona, where: p.redirect_id == ^from_id and
                              p.id != ^to_id)
    |> Repo.update_all(set: [redirect_id: to_id])

    from(p in Persona, where: p.redirect_id == ^from_id and
                              p.id == ^to_id)
    |> Repo.update_all(set: [redirect_id: nil])

    from(d in PanWeb.Delegation, where: d.persona_id == ^from_id and
                                 d.delegate_id != ^to_id)
    |> Repo.update_all(set: [persona_id: to_id])

    from(d in PanWeb.Delegation, where: d.delegate_id == ^from_id and
                                 d.persona_id != ^to_id)
    |> Repo.update_all(set: [delegate_id: to_id])

    from(d in PanWeb.Delegation, where: d.persona_id == ^from_id and
                                 d.delegate_id == ^to_id)
    |> Repo.delete_all()

    from(d in PanWeb.Delegation, where: d.persona_id == ^to_id and
                                 d.delegate_id == ^from_id)
    |> Repo.delete_all()

    from(m in PanWeb.Manifestation, where: m.persona_id == ^to_id)
    |> Repo.delete_all()

    Tirexs.HTTP.delete("http://127.0.0.1:9200/panoptikum_" <> Application.get_env(:pan, :environment) <>
                       "/personas/" <> Integer.to_string(from_id))

    to_persona = Repo.get!(Persona, to_id)
    from_persona = Repo.get!(Persona, from_id)

    if to_persona.uri == nil and from_persona.uri != nil do
      Persona.changeset(to_persona, %{uri: from_persona.uri})
      |> Repo.update()
    end

    if to_persona.email == nil and from_persona.email != nil do
      Persona.changeset(to_persona, %{email: from_persona.email})
      |> Repo.update()
    end

    if to_persona.image_url == nil and from_persona.image_url != nil do
      Persona.changeset(to_persona, %{image_url: from_persona.image_url})
      |> Repo.update()
    end

    if to_persona.image_title == nil and from_persona.image_title != nil do
      Persona.changeset(to_persona, %{image_title: from_persona.image_title})
      |> Repo.update()
    end

    if to_persona.description == nil and from_persona.description != nil do
      Persona.changeset(to_persona, %{description: from_persona.description})
      |> Repo.update()
    end

    if to_persona.long_description == nil and from_persona.long_description != nil do
      Persona.changeset(to_persona, %{long_description: from_persona.long_description})
      |> Repo.update()
    end

    Repo.delete!(from_persona)
    Persona.delete_search_index(from_id)
    Persona.update_search_index(to_id)
    render(conn, "merge.html")
  end
end
