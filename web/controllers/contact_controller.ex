defmodule Crm.ContactController do
  use Crm.Web, :controller
  use Drab.Controller

  alias Crm.{Contact, ContactGroup, Note}

  plug :assign_user_id_to_session when action in [:new]

  def index(conn, params) do
    groups = ContactGroup.all(conn.assigns.current_user.id)
    {contacts, kerosene} = Contact.all(
      conn.assigns.current_user.id,
      params
    )

    render(conn, :index,
      contacts: contacts,
      groups: groups,
      kerosene: kerosene
    )
  end

  def show(conn, params) do
    contacts_count = Contact.count(conn.assigns.current_user.id)
    conn = put_session(conn, :contact_id, String.to_integer(params["id"]))
    {notes, kerosene} = Note.all(params["id"], params)
    groups = ContactGroup.all(conn.assigns.current_user.id)
    contact = Repo.get!(
      Contact, params["id"]
    ) |> Repo.preload(:contact_group)

    render(conn, :show,
      contact: contact,
      groups: groups,
      notes: notes,
      kerosene: kerosene,
      contacts_count: contacts_count)
  end

  def search(conn, params) do
    contacts_count = Contact.count(conn.assigns.current_user.id)
    groups = ContactGroup.all(conn.assigns.current_user.id)
    {contacts, kerosene} = Contact.search(
      conn.assigns.current_user.id,
      params["q"],
      params
    )

    render(conn, :search,
      contacts: contacts,
      groups: groups,
      kerosene: kerosene,
      contacts_count: contacts_count
    )
  end

  def groups(conn, params) do
    group_id = String.to_integer(params["id"])
    groups = ContactGroup.all(conn.assigns.current_user.id)
    contacts_count = Contact.count(conn.assigns.current_user.id)
    {contacts, kerosene} = Contact.all_contacts_for_group(
      group_id,
      params
    )

    render(conn, :groups,
      contacts: contacts,
      groups: groups,
      kerosene: kerosene,
      contacts_count: contacts_count
    )
  end

  def new(conn, _params) do
    contacts_count = Contact.count(conn.assigns.current_user.id)
    groups = ContactGroup.all(conn.assigns.current_user.id)
    changeset = Contact.changeset(%Contact{})
    render(conn, :new, 
      changeset: changeset,
      groups: groups,
      contacts_count: contacts_count)
  end

  def create(conn, %{"contact" => contact_params}) do
    groups = Repo.all(ContactGroup)
    group = String.to_integer(contact_params["contact_group_id"])
    changeset = Contact.changeset(%Contact{
      contact_group_id: group,
      user_id: conn.assigns.current_user.id
    }, contact_params)

    case Repo.insert(changeset) do
      {:ok, contact} ->
        conn
        |> put_flash(:info, "#{contact.name} created!")
        |> redirect(to: contact_path(conn, :index))
      {:error, changeset} ->
        render(conn, :new, changeset: changeset, groups: groups)
    end
  end

  def edit(conn, %{"id" => id}) do
    groups = ContactGroup.all(conn.assigns.current_user.id)
    contact = Repo.get!(Contact, id)
    changeset = Contact.changeset(contact)
    render(conn, :edit,
      contact: contact,
      changeset: changeset,
      groups: groups)
  end

  def update(conn, %{"id" => id, "contact" => contact_params}) do
    groups = ContactGroup.all(conn.assigns.current_user.id)
    contact = Repo.get!(Contact, id)
    changeset = Contact.changeset(contact, contact_params)
    case Repo.update(changeset) do
      {:ok, contact} ->
        conn
        |> put_flash(:info, "#{contact.name} updated successfully.")
        |> redirect(to: contact_path(conn, :show, contact))
      {:error, changeset} ->
        render(conn, "edit.html",
        contact: contact,
        changeset: changeset,
        groups: groups)
    end
  end

  def delete(conn, %{"id" => id}) do
    contact = Repo.get!(Contact, id)
    Repo.delete!(contact)
    conn
    |> put_flash(:info, "Contact #{contact.name} deleted successfully.")
    |> redirect(to: contact_path(conn, :index))
  end

  defp assign_user_id_to_session(conn, _) do
    if conn.assigns.current_user do
      conn = put_session(conn, :user_id, conn.assigns.current_user.id)
    end
    conn
  end
end
