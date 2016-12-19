defmodule Pan.SessionController do
  use Pan.Web, :controller

  def new(conn, _) do
    render conn, "new.html"
  end

  def create(conn, %{"session" =>  %{"username" => user, "password" => pass}}) do
    case Pan.Auth.login_by_username_and_pass(conn, user, pass) do
      {:ok, conn} ->
        current_user = conn.assigns.current_user
        case current_user.email_confirmed do
          true ->
            conn
            |> put_flash(:info, "Welcome back!")
          _ ->
            Phoenix.Token.sign(Pan.Endpoint, "user", current_user.id)
            |> Pan.Email.email_confirmation_link_html_email(current_user.email)
            |> Pan.Mailer.deliver_now()

            conn
            |> Phoenix.Controller.put_flash(:info,
                 "Your email address has not been confirmed yet. Please click on " <>
                 "the confirmation link in the email we sent to you right now!"
               )
        end
        |> redirect(to: category_frontend_path(conn, :index))
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username/password combination!")
        |> render("new.html")
    end
  end


  def login_via_token(conn, %{"token" => token}) do
    case Pan.Auth.login_by_token(conn, token) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back, please set your new password!")
        |> redirect(to: user_frontend_path(conn, :edit_password))
      {:error, :expired} ->
        conn
        |> put_flash(:error, "The token has expired already!")
        |> render("new.html")
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid token!")
        |> render("new.html")
    end
  end


  def delete(conn, _) do
    conn
    |> Pan.Auth.logout()
    |> redirect(to: podcast_frontend_path(conn, :index))
  end


  def confirm_email(conn, %{"token" => token}) do
    case Pan.Auth.login_by_token(conn, token) do
      {:ok, conn} ->
        Ecto.Changeset.change(conn.assigns.current_user, email_confirmed: true)
        |> Repo.update

        conn
        |> put_flash(:info, "Thank you for confirming your email address!")
        render(conn, "email_confirmed.html")
      {:error, :expired} ->
        conn
        |> put_flash(:error, "The token has expired already!")
        |> render("new.html")
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid token!")
        |> render("new.html")
    end
  end
end