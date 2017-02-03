defmodule Pan.DelegationControllerTest do
  use Pan.ConnCase

  alias Pan.Delegation
  @valid_attrs %{}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, delegation_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing delegations"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, delegation_path(conn, :new)
    assert html_response(conn, 200) =~ "New delegation"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, delegation_path(conn, :create), delegation: @valid_attrs
    assert redirected_to(conn) == delegation_path(conn, :index)
    assert Repo.get_by(Delegation, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, delegation_path(conn, :create), delegation: @invalid_attrs
    assert html_response(conn, 200) =~ "New delegation"
  end

  test "shows chosen resource", %{conn: conn} do
    delegation = Repo.insert! %Delegation{}
    conn = get conn, delegation_path(conn, :show, delegation)
    assert html_response(conn, 200) =~ "Show delegation"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, delegation_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    delegation = Repo.insert! %Delegation{}
    conn = get conn, delegation_path(conn, :edit, delegation)
    assert html_response(conn, 200) =~ "Edit delegation"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    delegation = Repo.insert! %Delegation{}
    conn = put conn, delegation_path(conn, :update, delegation), delegation: @valid_attrs
    assert redirected_to(conn) == delegation_path(conn, :show, delegation)
    assert Repo.get_by(Delegation, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    delegation = Repo.insert! %Delegation{}
    conn = put conn, delegation_path(conn, :update, delegation), delegation: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit delegation"
  end

  test "deletes chosen resource", %{conn: conn} do
    delegation = Repo.insert! %Delegation{}
    conn = delete conn, delegation_path(conn, :delete, delegation)
    assert redirected_to(conn) == delegation_path(conn, :index)
    refute Repo.get(Delegation, delegation.id)
  end
end