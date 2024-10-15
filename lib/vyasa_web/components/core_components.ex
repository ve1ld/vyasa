defmodule VyasaWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use Gettext, backend: VyasaWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{}, doc: "JS cancel action")
  attr(:on_confirm, JS, default: %JS{}, doc: "JS confirm action")
  attr(:background, :string, default: "bg-white")
  attr(:close_button, :boolean, default: true)
  attr(:main_width, :string, default: "w-full")

  slot(:inner_block, required: true)

  slot(:confirm) do
    attr(:tone, :atom)
  end

  slot(:cancel)

  def modal_wrapper(assigns) do
    ~H"""
    <div id={@id} phx-mounted={@show && show_modal(@id)} class="relative z-50 hidden w-full mx-auto">
      <div
        id={"#{@id}-bg"}
        class={["fixed inset-0 bg-gray-500 dark:bg-black opacity-90 dark:opacity-80", @background]}
        aria-hidden="true"
      />
      <div
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
        class="w-full fixed inset-0 flex"
      >
        <div class="flex w-full absolute lg:inset-0 bottom-0 lg:items-center lg:justify-center">
          <div class={["w-full lg:py-8 rounded-none lg:rounded-2xl", @main_width]}>
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && show_modal(@id)}
              phx-window-keydown={hide_modal(@on_cancel, @id)}
              phx-key="escape"
              phx-click-away={hide_modal(@on_cancel, @id)}
              class="hidden relative flex w-full bg-white lg:rounded-3xl lg:shadow-2xl"
            >
              <div :if={@close_button} class="absolute top-4 right-4">
                <button
                  phx-click={hide_modal(@on_cancel, @id)}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-80 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5 text-white" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <div
                  id={"#{@id}-main"}
                  class="w-full lg:max-w-2xl lg:items-center lg:justify-center flex"
                >
                  <%= render_slot(@inner_block) %>
                </div>
                <div
                  :if={@confirm != [] or @cancel != []}
                  class="p-4 flex flex-row-reverse items-center gap-5"
                >
                  <.button
                    :for={confirm <- @confirm}
                    id={"#{@id}-confirm"}
                    tone={Map.get(confirm, :tone, :primary)}
                    phx-click={@on_confirm}
                    phx-disable-with
                    class="py-2 px-3"
                  >
                    <%= render_slot(confirm) %>
                  </.button>
                  <.link
                    :for={cancel <- @cancel}
                    phx-click={hide_modal(@on_cancel, @id)}
                    class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                  >
                    <%= render_slot(cancel) %>
                  </.link>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)

  attr(:on_cancel_callback, JS,
    default: %JS{},
    doc: "Defines a callback to invoke on cancellation / exit of the modal"
  )

  attr(:on_click_away_callback, :any,
    default: %JS{},
    doc: "Defines a callback to invoke on click away of dialog"
  )

  attr(:cancel_key, :string, default: "escape")

  attr(:on_mount_callback, :any,
    default: %JS{},
    doc: "Defines a callback to invoke on mounting of the modal"
  )

  attr(:window_keydown_callback, :any,
    default: %JS{},
    doc: "Defines a callback to invoke on keypress @ the window level"
  )

  attr(:container_class, :string, default: "", doc: "inline style for the outermost container")
  attr(:background_class, :string, default: "", doc: "inline style for the background / backdrop")
  attr(:dialog_class, :string, default: "", doc: "inline style for the dialog container")
  attr(:focus_wrap_class, :string, default: "", doc: "inline style for the focus wrap")

  attr(:inner_block_container_class, :string,
    default: "",
    doc: "inline style for the container for the inner content slot"
  )

  attr(:close_button_icon, :string, default: "hero-x-mark-solid")
  attr(:close_button_class, :string, default: "")
  attr(:close_button_icon_class, :string, default: "")
  attr(:focus_container_class, :string, default: "")

  slot(:inner_block, required: true)

  @doc """
  A generic implementation of the modal wrapper. The attributes and slots have corresponding docstrings for reference.
  In order to use this:
  1) supply the show boolean properly, this controls hidden state
  2) supply some callbacks:
     Most of these callbacks target a particular event, the caveat is that if there are
     multiple events that are expected to fire the same callback, then the current implementation
     requires some duplication of the callbacks passed.

     For example, if you pass in a callback for on_cancel_callback, you would probably
     want to do the same for the on_click_away_callback. Currently this duplication
     is required, in the future if there's no reason to target these events separately,
     then the function component definition might be changed such that closing and click-away
     callbacks refer to the same argument.

  3) supply some class definitions to override the default ones provided in this function definition.
     By inspecting the attributes corresponding to class definitions, we can also determine how this
     modal-wrapper is structured (containers, children...)
  """
  def generic_modal_wrapper(assigns) do
    IO.inspect(assigns, label: "SEE ME: modal wrapper assigns")

    ~H"""
    <div
      :if={@show}
      id={@id}
      phx-mounted={@show && @on_mount_callback && show_modal(@id)}
      class={["relative z-50 hidden w-full mx-auto", @container_class]}
    >
      <div
        id={"#{@id}-bg"}
        class={[
          "fixed inset-0 bg-gray-500 dark:bg-black opacity-90 dark:opacity-80 border border-red-500",
          @background_class
        ]}
        aria-hidden="true"
      />
      <div
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
        class={["w-full fixed inset-0 flex border border-green-500", @dialog_class]}
      >
        <div class="border border-blue-500 flex h-full w-full absolute lg:inset-0 bottom-0 lg:items-center lg:justify-center">
          <div class={["w-full h-full rounded-none rounded-2xl", @focus_container_class]}>
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && @on_mount_callback && show_modal(@id)}
              phx-window-keydown={hide_modal(@window_keydown_callback, @id)}
              phx-key={@cancel_key}
              phx-click-away={hide_modal(@on_click_away_callback, @id)}
              class={[
                "hidden relative flex w-full bg-white lg:rounded-3xl lg:shadow-2xl overflow-auto",
                @focus_wrap_class
              ]}
            >
              <div :if={@close_button_icon} class="absolute top-4 right-4">
                <button
                  phx-click={hide_modal(@on_cancel_callback, @id)}
                  type="button"
                  class={["-m-3 flex-none p-3 opacity-80 hover:opacity-40", @close_button_class]}
                  aria-label={gettext("close")}
                >
                  <.icon
                    name={@close_button_icon}
                    class={"h-5 w-5 text-black " <> (@close_button_icon_class || "")}
                  />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <div
                  id={"#{@id}-main"}
                  class={[
                    "w-full lg:max-w-2xl lg:items-center lg:justify-center flex",
                    @inner_block_container_class
                  ]}
                >
                  <%= render_slot(@inner_block) %>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a waiting spinner
  """
  def spinner(assigns) do
    ~H"""
    <svg
      class="animate-spin h-10 w-10 text-blue-500"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="orange" stroke-width="4"></circle>
      <path
        class="opacity-75"
        fill="orange"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 6.627 5.373 12 12 12v-4a7.946 7.946 0 01-6-2.709z"
      >
      </path>
    </svg>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title="Success!" flash={@flash} />
      <.flash kind={:error} title="Error!" flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title="We can't find the internet"
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        Hang in there while we get back on track
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil

  attr(:tone, :atom,
    default: :primary,
    values: ~w(primary inline success warning danger)a,
    doc: "Theme of the button"
  )

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        button_class(@tone),
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp button_class(:primary),
    do:
      "focus:outline-none focus:ring-4 font-bold rounded-xl lg:text-base text-sm px-5 py-2.5 text-center bg-[#9747FF] text-[#D1D1D1] hover:bg-purple-700 focus:ring-purple-900 font-poppins"

  defp button_class(:inline),
    do:
      "inline-flex items-center justify-center w-10 h-10 rounded-full bg-white/30 dark:bg-gray-800/30 group-hover:bg-white/50 dark:group-hover:bg-gray-800/60 group-focus:ring-4 group-focus:ring-white dark:group-focus:ring-gray-800/70 group-focus:outline-none"

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc """
  Renders a sidenote w action slots for interaction with sidenote
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  slot :quote
  slot :subtitle
  slot :actions

  def sidenote(assigns) do
    ~H"""
    <header class={[@actions == [] && "w-64 bg-white rounded-md shadow-xl p-px", @class]}>
      <!-- Comment Header -->
      <div class="text-black">
        <div class="rounded pt-0 pb-3">
          <!-- User Info Section -->
          <div class="flex flex-col pt-2">
            <div class="flex items-start text-sm leading-5">
              <div class="flex-grow">
                <!-- User Profile Section -->
                <div class="flex items-center pt-1 pr-4 pb-0 pl-3 select-none">
                  <div class="mr-2">
                    <div class="w-5 h-5 overflow-hidden">
                      <!-- User Profile Image -->
                      <img
                        src="https://yt3.ggpht.com/3L3vTo8jRmmhs1DPOyriFSxav8BZK87btsSd3taeiwo9a2T5bjzCBKscy1NeFZJbKMlTVKhg=s88-c-k-c0x00ffffff-no-rj"
                        class="block object-cover w-full h-full rounded-full"
                      />
                    </div>
                  </div>
                  <!-- User Info -->
                  <div class="overflow-hidden">
                    <span class="font-semibold">Anonymous</span>
                    <div class="inline ml-20 text-xs text-gray-500">Jan 7</div>
                  </div>
                </div>
                <!-- Comment Content Section -->
                <div class="pt-px pr-4 pb-1 pl-10">
                  <div :if={@quote != []} class="flex">
                    <!-- Comment Indicator -->
                    <div class="pb-px mr-2 w-1 bg-yellow-500 rounded"></div>
                    <div class="overflow-hidden">
                      <span class="text-left no-underline">
                        <%= render_slot(@quote) %>
                      </span>
                    </div>
                  </div>
                  <!-- Comment Text Section -->
                  <div class="mt-4 pl-0 max-w-full" spellcheck="true" contenteditable="false">
                    private posts
                  </div>
                </div>
              </div>
              <!-- Action Buttons Section -->
              <div class="flex-shrink-0 ml-2">
                <!-- Add your buttons here -->
              </div>
            </div>
          </div>
          <!-- Comment Input Section -->
          <div class="relative pt-1 pr-3 pl-2">
            <div class="flex flex-col w-full cursor-pointer">
              <div class="flex items-center flex-grow">
                <!-- Comment Input Box -->
                <div class="flex flex-col self-center w-full text-sm leading-5 rounded cursor-text">
                  <div
                    class="max-w-full whitespace-pre-wrap"
                    spellcheck="true"
                    contenteditable="true"
                    placeholder="Reply..."
                  ></div>
                  <div class="inline-block items-center absolute bottom-0 right-0 opacity-1">
                    <!-- Comment Action Buttons Section -->
                    <div class="flex items-left ">
                      <button class="inline-block items-center p-0 mr-5 w-5 h-5 rounded pointer-events-auto select-none">
                        <svg
                          role="graphics-symbol"
                          viewBox="0 0 20 20"
                          class="block flex-shrink-0 w-6 h-6 align-middle"
                        >
                          <path d="M9.79883 18.5894C14.6216 18.5894 18.5894 14.6216 18.5894 9.79883C18.5894 4.96777 14.6216 1 9.79053 1C4.95947 1 1 4.96777 1 9.79883C1 14.6216 4.96777 18.5894 9.79883 18.5894ZM9.79883 14.3062C9.20947 14.3062 8.76953 13.9077 8.76953 13.3433V9.69922L8.86914 8.00586L8.25488 8.84424L7.3916 9.81543C7.23389 10.0063 6.98486 10.1143 6.72754 10.1143C6.21289 10.1143 5.84766 9.75732 5.84766 9.25928C5.84766 8.99365 5.92236 8.79443 6.12158 8.58691L8.96045 5.61523C9.19287 5.35791 9.4585 5.2417 9.79883 5.2417C10.1309 5.2417 10.4048 5.36621 10.6372 5.61523L13.4761 8.58691C13.667 8.79443 13.75 8.99365 13.75 9.25928C13.75 9.75732 13.3848 10.1143 12.8618 10.1143C12.6128 10.1143 12.3638 10.0063 12.2061 9.81543L11.3428 8.86914L10.7202 7.99756L10.8281 9.69922V13.3433C10.8281 13.9077 10.3799 14.3062 9.79883 14.3062Z">
                          </path>
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal"><%= col[:label] %></th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only"><%= gettext("Actions") %></span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <%= render_slot(@inner_block) %>
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt :if={Map.has_key?(item, :title)} class="w-1/6 flex-none text-zinc-500">
            <%= item.title %>
          </dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, default: nil
  attr :patch, :any, default: nil
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <%= if @patch do %>
        <.link
          patch={@patch}
          class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
        >
          <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
          <%= render_slot(@inner_block) %>
        </.link>
      <% else %>
        <.link
          navigate={@navigate}
          class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
        >
          <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
          <%= render_slot(@inner_block) %>
        </.link>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  def icon(%{name: "custom-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(VyasaWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(VyasaWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  A generic debug dump component that displays all assigned properties.

  ## Examples
      <DebugDump assigns={@assigns} label="Custom Label" class={["custom-class", "another-class"]} />
  """
  def debug_dump(assigns) do
    ~H"""
    <div class={[
      "fixed bottom-0 right-0 m-4 p-4 bg-white border border-gray-300 rounded-lg shadow-lg max-w-md max-h-80 overflow-auto z-50 bg-opacity-50",
      Map.get(assigns, :class, "")
    ]}>
      <h2 class="text-lg font-bold mb-2">
        <%= Map.get(assigns, :label, "Developer Dump") %>
      </h2>
      <div>
        <h3 class="text-md font-bold mb-2">Parameters:</h3>
        <pre class="p-2 rounded-md whitespace-pre-wrap">
          <%= inspect(assigns, pretty: true) %>
        </pre>
      </div>
    </div>
    """
  end
end
