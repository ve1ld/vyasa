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

  alias Phoenix.LiveView.JS
  import VyasaWeb.Gettext

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
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

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

  # def sidenote(assigns) do
  #   ~H"""
  #   <header class={[@actions != [] && "sidenote", @class]}>
  #     <div>
  #       <h1 class="text-lg font-semibold sidenote text-zinc-800">
  #         <%= render_slot(@inner_block) %>
  #       </h1>
  #       <p :if={@subtitle != []} class="mt-2 text-sm sidenote leading-6 text-zinc-600">
  #         <%= render_slot(@subtitle) %>
  #       </p>
  #     </div>
  #     <div class="flex-none"><%= render_slot(@actions) %></div>
  #   </header>
  #   """
  # end
  #
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
                      <img src="https://yt3.ggpht.com/3L3vTo8jRmmhs1DPOyriFSxav8BZK87btsSd3taeiwo9a2T5bjzCBKscy1NeFZJbKMlTVKhg=s88-c-k-c0x00ffffff-no-rj" class="block object-cover w-full h-full rounded-full">
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
                 <div class="max-w-full whitespace-pre-wrap" spellcheck="true" contenteditable="true" placeholder="Reply..."></div>
                  <div class="inline-block items-center absolute bottom-0 right-0 opacity-1">
                   <!-- Comment Action Buttons Section -->
                   <div class="flex items-left ">
                     <button class="inline-block items-center p-0 mr-5 w-5 h-5 rounded pointer-events-auto select-none">
                     <svg role="graphics-symbol" viewBox="0 0 20 20" class="block flex-shrink-0 w-6 h-6 align-middle">
                      <path d="M9.79883 18.5894C14.6216 18.5894 18.5894 14.6216 18.5894 9.79883C18.5894 4.96777 14.6216 1 9.79053 1C4.95947 1 1 4.96777 1 9.79883C1 14.6216 4.96777 18.5894 9.79883 18.5894ZM9.79883 14.3062C9.20947 14.3062 8.76953 13.9077 8.76953 13.3433V9.69922L8.86914 8.00586L8.25488 8.84424L7.3916 9.81543C7.23389 10.0063 6.98486 10.1143 6.72754 10.1143C6.21289 10.1143 5.84766 9.75732 5.84766 9.25928C5.84766 8.99365 5.92236 8.79443 6.12158 8.58691L8.96045 5.61523C9.19287 5.35791 9.4585 5.2417 9.79883 5.2417C10.1309 5.2417 10.4048 5.36621 10.6372 5.61523L13.4761 8.58691C13.667 8.79443 13.75 8.99365 13.75 9.25928C13.75 9.75732 13.3848 10.1143 12.8618 10.1143C12.6128 10.1143 12.3638 10.0063 12.2061 9.81543L11.3428 8.86914L10.7202 7.99756L10.8281 9.69922V13.3433C10.8281 13.9077 10.3799 14.3062 9.79883 14.3062Z"></path>
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
  # def sidenote() do
  #   ~H"""
  #   <div
  #     class="p-px w-64 leading-6 text-black bg-white rounded-md shadow-xs">
  #     <div data-block-id="1019dbe4-4518-4df9-a3f9-ba94cf44b493" class="text-black">
  #       <div
  #         class="pt-0 pb-3 rounded">
  #         <div
  #           class="flex flex-col pt-2 mr-0 mb-0">
  #           <div class="">
  #             <div
  #               style="display: flex; align-items: flex-start; position: relative; font-size: 14px;"
  #               class="flex relative items-start text-sm leading-5">
  #               <div style="flex-grow: 1; min-width: 0px;" class="flex-grow">
  #                 <div
  #                   class="flex relative flex-row items-center pt-1 pr-4 pb-0 pl-3 select-none">
  #                   <div
  #                     class="mt-px mr-2 select-none">
  #                     <div
  #                       class="shadow-xs">
  #                       <div
  #                         class="flex justify-center items-center w-5 h-5 opacity-100 select-none">
  #                         <div
  #                           class="w-full h-full">
  #                           <img
  #                             src="https://yt3.ggpht.com/3L3vTo8jRmmhs1DPOyriFSxav8BZK87btsSd3taeiwo9a2T5bjzCBKscy1NeFZJbKMlTVKhg=s88-c-k-c0x00ffffff-no-rj"
  #                             referrerpolicy="same-origin"
  #                             class="block object-cover w-full max-w-full h-full align-middle"
  #                           />
  #                         </div>
  #                       </div>
  #                     </div>
  #                   </div>
  #                   <div class="overflow-hidden">
  #                     <span
  #                       class="font-semibold whitespace-normal"> A.Vivekbala</span>
  #                     <div
  #                       class="inline flex-grow my-0 mx-1 text-xs leading-4 text-gray-500 whitespace-normal">
  #                       <div class="inline">Jan 7</div>
  #                     </div>
  #                   </div>
  #                 </div>
  #                 <div
  #                   class="pt-px pr-4 pb-1 pl-10">
  #                   <div class="relative">
  #                     <div>
  #                       <div class="flex w-full">
  #                         <div class="flex-shrink-0 pb-px mr-2 ml-px w-1 bg-yellow-500 rounded" ></div>
  #                         <div class="overflow-hidden">
  #                             <span class="text-left no-underline"> bhagavan uvacha</span>
  #                       </div>
  #                       </div>
  #                         <div
  #                           spellcheck="true"
  #                           data-content-editable-leaf="true"
  #                           contenteditable="false"
  #                           class="pl-0 w-full max-w-full whitespace-pre-wrap cursor-text">
  #                           private posts
  #                         </div>
  #                       </div>
  #                     </div>

  #                 </div>
  #               </div>
  #               <div
  #                 style="display: flex; box-shadow: rgba(15, 15, 15, 0.1) 0px 0px 0px 1px, rgba(15, 15, 15, 0.1) 0px 2px 4px; position: absolute; flex-shrink: 0; padding: 2px; background-color: white; margin-right: 0px; margin-top: 0px; right: 12px; top: 6px; opacity: 0; gap: 1px; border-radius: 4px; transition: opacity 100ms ease-out 0s; z-index: 1;"
  #                 class="flex absolute flex-shrink-0 gap-px p-px mt-0 mr-0 rounded opacity-0 shadow-xs">
  #                 <div
  #                   role="button"
  #                   tabindex="0"
  #                   style="user-select: none; transition: background 20ms ease-in 0s; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; flex: 0 0 auto; border-radius: 4px; height: 22px; width: 22px; padding: 0px;"
  #                   class="inline-flex flex-none justify-center items-center p-0 w-5 h-5 rounded cursor-pointer select-none">
  #                   <svg
  #                     role="graphics-symbol"
  #                     viewBox="0 0 16 16"
  #                     style="width: 15px; height: 100%; display: block; fill: rgba(55, 53, 47, 0.45); flex-shrink: 0;"
  #                     class="block flex-shrink-0 w-4 h-full align-middle">
  #                     <g class="">
  #                       <path
  #                         d="M8.7207 12.0259C8.7207 12.4243 9.04492 12.7446 9.43945 12.7446H11.4199V14.7251C11.4199 15.1235 11.7441 15.4438 12.1426 15.4438C12.5371 15.4438 12.8613 15.1235 12.8613 14.7251V12.7446H14.8418C15.2363 12.7446 15.5605 12.4243 15.5605 12.0259C15.5605 11.6274 15.2363 11.3032 14.8418 11.3032H12.8613V9.32666C12.8613 8.92822 12.5371 8.604 12.1426 8.604C11.7441 8.604 11.4199 8.92822 11.4199 9.32666V11.3032H9.43945C9.04492 11.3032 8.7207 11.6274 8.7207 12.0259Z"
  #                         class="">                        </path>
  #                       <path
  #                         fill-rule="evenodd"
  #                         clip-rule="evenodd"
  #                         d="M9.02947 13.6952C8.43019 13.8731 7.79681 13.9688 7.14258 13.9688C3.46729 13.9688 0.439453 10.9409 0.439453 7.25928C0.439453 3.58398 3.46094 0.556152 7.14258 0.556152C10.8179 0.556152 13.8457 3.58398 13.8457 7.25928C13.8457 7.72257 13.7979 8.1755 13.7069 8.61336C13.439 8.02567 12.8508 7.61289 12.1648 7.60415C12.1724 7.49021 12.1763 7.37521 12.1763 7.25928C12.1763 4.47266 9.9292 2.22559 7.14258 2.22559C4.34961 2.22559 2.11523 4.47266 2.11523 7.25928C2.11523 10.0522 4.35596 12.2993 7.14258 12.2993C7.34385 12.2993 7.54226 12.2876 7.73717 12.2649C7.83478 12.9674 8.35636 13.53 9.02947 13.6952ZM6.02539 5.83105C6.02539 6.31982 5.67627 6.67529 5.28271 6.67529C4.88916 6.67529 4.55908 6.31982 4.55908 5.83105C4.55908 5.33594 4.88916 4.98047 5.28271 4.98047C5.67627 4.98047 6.02539 5.33594 6.02539 5.83105ZM9.73242 5.83105C9.73242 6.31982 9.3833 6.67529 8.99609 6.67529C8.60254 6.67529 8.26611 6.31982 8.26611 5.83105C8.26611 5.33594 8.59619 4.98047 8.99609 4.98047C9.38965 4.98047 9.73242 5.33594 9.73242 5.83105ZM9.37695 8.9668C9.37695 9.39844 8.48193 10.2808 7.14258 10.2808C5.79688 10.2808 4.90186 9.39844 4.90186 8.9668C4.90186 8.80811 5.06055 8.72559 5.21289 8.80176L5.22971 8.81029C5.68936 9.04333 6.22701 9.31592 7.14258 9.31592C8.01512 9.31592 8.53968 9.05921 8.99207 8.83782C9.01689 8.82568 9.04149 8.81364 9.06592 8.80176C9.21826 8.73193 9.37695 8.80811 9.37695 8.9668Z"
  #                         class="">                        </path>
  #                     </g>
  #                   </svg>
  #                 </div>
  #                 <div
  #                   role="button"
  #                   tabindex="0"
  #                   style="user-select: none; transition: background 20ms ease-in 0s; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; flex: 0 0 auto; border-radius: 4px; height: 22px; width: 22px; padding: 0px;"
  #                   class="inline-flex flex-none justify-center items-center p-0 w-5 h-5 rounded cursor-pointer select-none">
  #                   <svg
  #                     role="graphics-symbol"
  #                     viewBox="0 0 16 16"
  #                     style="width: 14px; height: 14px; display: block; fill: rgba(55, 53, 47, 0.45); flex-shrink: 0;"
  #                     class="block flex-shrink-0 w-3 h-3 align-middle">
  #                     <path
  #                       d="M6.6123 14.2646C7.07715 14.2646 7.43945 14.0869 7.68555 13.7109L14.0566 3.96973C14.2344 3.69629 14.3096 3.44336 14.3096 3.2041C14.3096 2.56152 13.8311 2.09668 13.1748 2.09668C12.7236 2.09668 12.4434 2.26074 12.1699 2.69141L6.57812 11.5098L3.74121 7.98926C3.48828 7.68848 3.21484 7.55176 2.83203 7.55176C2.16895 7.55176 1.69043 8.02344 1.69043 8.66602C1.69043 8.95312 1.7793 9.20605 2.02539 9.48633L5.55273 13.7588C5.84668 14.1074 6.1748 14.2646 6.6123 14.2646Z"
  #                       class="">                      </path>
  #                   </svg>
  #                 </div>
  #                 <div
  #                   role="button"
  #                   tabindex="0"
  #                   style="user-select: none; transition: background 20ms ease-in 0s; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; flex: 0 0 auto; border-radius: 4px; height: 22px; width: 22px; padding: 0px;"
  #                   class="inline-flex flex-none justify-center items-center p-0 w-5 h-5 rounded cursor-pointer select-none">
  #                   <svg
  #                     role="graphics-symbol"
  #                     viewBox="0 0 13 3"
  #                     style="width: 14px; height: 14px; display: block; fill: rgba(55, 53, 47, 0.45); flex-shrink: 0;"
  #                     class="block flex-shrink-0 w-3 h-3 align-middle">
  #                     <g class="">
  #                       <path
  #                         d="M3,1.5A1.5,1.5,0,1,1,1.5,0,1.5,1.5,0,0,1,3,1.5Z"
  #                         class="">                        </path>
  #                       <path
  #                         d="M8,1.5A1.5,1.5,0,1,1,6.5,0,1.5,1.5,0,0,1,8,1.5Z"
  #                         class="">                        </path>
  #                       <path
  #                         d="M13,1.5A1.5,1.5,0,1,1,11.5,0,1.5,1.5,0,0,1,13,1.5Z"
  #                         class="">                        </path>
  #                     </g>
  #                   </svg>
  #                 </div>
  #               </div>
  #             </div>
  #           </div>
  #         </div>
  #         <div
  #           style="padding: 4px 12px 0px 9px; position: relative;"
  #           class="relative pt-1 pr-3 pb-0 pl-2">
  #           <div
  #             class="flex flex-col pr-px pl-1 w-full cursor-pointer"
  #             style="display: flex; flex-direction: column; width: 100%; cursor: pointer; padding-left: 5px; padding-right: 2px;">
  #             <div
  #               style="display: flex; align-items: center; flex-grow: 1;"
  #               class="flex flex-grow items-center">
  #               <div
  #                 class="flex relative flex-col self-center pt-px pb-8 w-full text-sm leading-5 rounded cursor-text shadow-xs"
  #                 style="display: flex; flex-direction: column; width: 100%; font-size: 14px; padding-top: 1px; padding-bottom: 34px; border-radius: 4px; box-shadow: rgba(55, 53, 47, 0.16) 0px 0px 0px 1px; transition-delay: 0s; background: white; cursor: text; align-self: center; position: relative;"
  #                 tabindex="-1">
  #                 <div style="flex-grow: 1; display: flex;" class="flex flex-grow">
  #                   <div
  #                     class="pr-2 pl-1 mt-1 mb-px w-full max-w-full whitespace-pre-wrap select-auto"
  #                     style="max-width: 100%; width: 100%; white-space: pre-wrap; word-break: break-word; caret-color: rgb(55, 53, 47); font-size: 14px; margin-top: 3px; margin-bottom: 2px; padding-left: 6px; padding-right: 10px; max-height: 70vh; overflow: hidden auto; user-select: auto;"
  #                     spellcheck="true"
  #                     placeholder="Reply..."
  #                     data-content-editable-leaf="true"
  #                     contenteditable="true">
  #                     wow
  #                   </div>
  #                 </div>
  #                 <div
  #                   style="display: flex; flex-direction: row; position: absolute; bottom: 7px; right: 12px; align-items: center; opacity: 1;"
  #                   class="flex absolute flex-row items-center opacity-100">
  #                   <div
  #                     style="display: flex; flex-direction: row; align-items: center;"
  #                     class="flex flex-row items-center">
  #                     <div
  #                       role="button"
  #                       tabindex="0"
  #                       style="user-select: none; transition: background 20ms ease-in 0s; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; flex-shrink: 0; border-radius: 4px; height: 24px; width: 24px; padding: 0px; margin-left: 10px;"
  #                       aria-label="Attach file"
  #                       class="inline-flex flex-shrink-0 justify-center items-center p-0 ml-2 w-6 h-6 rounded select-none">
  #                       <svg
  #                         role="graphics-symbol"
  #                         viewBox="0 0 20 20"
  #                         style="width: 16px; height: 16px; display: block; fill: rgba(55, 53, 47, 0.45); flex-shrink: 0;"
  #                         class="block flex-shrink-0 w-4 h-4 align-middle">
  #                         <path
  #                           d="M15.7608 10.5231L9.60997 16.674C8.07432 18.218 6.01573 18.0769 4.69591 16.7404C3.35948 15.4206 3.22667 13.3703 4.77061 11.8264L13.1959 3.39278C14.0758 2.51289 15.4039 2.33028 16.2755 3.20186C17.1554 4.08174 16.9645 5.40157 16.0846 6.28145L7.7838 14.5988C7.45177 14.9309 7.05333 14.8396 6.82091 14.6154C6.60509 14.383 6.51378 13.9929 6.84581 13.6525L12.6315 7.8669C12.9552 7.54317 12.9718 7.06172 12.6564 6.74629C12.3409 6.43916 11.8595 6.44746 11.5357 6.77119L5.7252 12.59C4.79551 13.5197 4.83702 14.9475 5.6588 15.7775C6.55528 16.674 7.91661 16.6491 8.8463 15.7194L17.1969 7.36885C18.8487 5.71699 18.7906 3.54219 17.338 2.08125C15.9103 0.661819 13.7023 0.57051 12.0504 2.22237L3.5587 10.7224C1.4171 12.864 1.55821 15.9602 3.51719 17.9191C5.47618 19.8781 8.57237 20.0192 10.7223 17.8776L16.9147 11.6853C17.2301 11.3781 17.2301 10.8054 16.9064 10.5065C16.5992 10.1745 16.0846 10.2077 15.7608 10.5231Z"
  #                           class="">                          </path>
  #                       </svg>
  #                     </div>
  #                     <div
  #                       role="button"
  #                       tabindex="0"
  #                       style="user-select: none; transition: background 20ms ease-in 0s; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; flex-shrink: 0; border-radius: 4px; height: 24px; width: 24px; padding: 0px; margin-left: 10px;"
  #                       aria-label="Mention a person, page, or date"
  #                       class="inline-flex flex-shrink-0 justify-center items-center p-0 ml-2 w-6 h-6 rounded select-none">
  #                       <svg
  #                         role="graphics-symbol"
  #                         viewBox="0 0 20 20"
  #                         style="width: 16px; height: 16px; display: block; fill: rgba(55, 53, 47, 0.45); flex-shrink: 0;"
  #                         class="block flex-shrink-0 w-4 h-4 align-middle">
  #                         <path
  #                           d="M1 9.86523C1 15.2939 4.72705 18.6807 9.98975 18.6807C11.3511 18.6807 12.4634 18.5312 13.1606 18.2905C13.6919 18.1079 13.8828 17.8174 13.8828 17.4521C13.8828 17.0537 13.6089 16.7715 13.1523 16.7715C13.0195 16.7715 12.8784 16.7881 12.6958 16.8213C11.9238 16.9873 11.2266 17.1118 10.2637 17.1118C5.74805 17.1118 2.74316 14.4058 2.74316 9.91504C2.74316 5.56543 5.61523 2.56055 9.88184 2.56055C13.7417 2.56055 16.7383 4.97607 16.7383 9.11816C16.7383 11.3511 15.9995 12.8452 14.8125 12.8452C14.0239 12.8452 13.5757 12.3472 13.5757 11.4839V6.44531C13.5757 5.84766 13.252 5.49072 12.6709 5.49072C12.0981 5.49072 11.7578 5.84766 11.7578 6.44531V7.10107H11.6333C11.21 6.09668 10.2305 5.49072 9.01855 5.49072C6.90186 5.49072 5.43262 7.28369 5.43262 9.89844C5.43262 12.5547 6.91846 14.3892 9.11816 14.3892C10.3799 14.3892 11.3013 13.7417 11.7578 12.6045H11.8823C12.1147 13.7168 13.0942 14.3809 14.4307 14.3809C16.8877 14.3809 18.3984 12.1895 18.3984 8.96045C18.3984 4.1626 14.8706 1 9.89014 1C4.66064 1 1 4.56104 1 9.86523ZM9.5415 12.7207C8.26318 12.7207 7.46631 11.6499 7.46631 9.92334C7.46631 8.21338 8.27148 7.14258 9.5498 7.14258C10.8364 7.14258 11.6582 8.20508 11.6582 9.89844C11.6582 11.625 10.8281 12.7207 9.5415 12.7207Z"
  #                           class="">                          </path>
  #                       </svg>
  #                     </div>
  #                     <div
  #                       role="button"
  #                       tabindex="0"
  #                       style="user-select: none; transition: background 20ms ease-in 0s; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; flex-shrink: 0; border-radius: 4px; height: 20px; width: 20px; padding: 0px; margin-left: 12px; pointer-events: auto;"
  #                       class="inline-flex flex-shrink-0 justify-center items-center p-0 ml-3 w-5 h-5 rounded pointer-events-auto select-none">
  #                       <svg
  #                         role="graphics-symbol"
  #                         viewBox="0 0 20 20"
  #                         style="width: 24px; height: 24px; display: block; fill: rgb(35, 131, 226); flex-shrink: 0;"
  #                         class="block flex-shrink-0 w-6 h-6 align-middle">
  #                         <path
  #                           d="M9.79883 18.5894C14.6216 18.5894 18.5894 14.6216 18.5894 9.79883C18.5894 4.96777 14.6216 1 9.79053 1C4.95947 1 1 4.96777 1 9.79883C1 14.6216 4.96777 18.5894 9.79883 18.5894ZM9.79883 14.3062C9.20947 14.3062 8.76953 13.9077 8.76953 13.3433V9.69922L8.86914 8.00586L8.25488 8.84424L7.3916 9.81543C7.23389 10.0063 6.98486 10.1143 6.72754 10.1143C6.21289 10.1143 5.84766 9.75732 5.84766 9.25928C5.84766 8.99365 5.92236 8.79443 6.12158 8.58691L8.96045 5.61523C9.19287 5.35791 9.4585 5.2417 9.79883 5.2417C10.1309 5.2417 10.4048 5.36621 10.6372 5.61523L13.4761 8.58691C13.667 8.79443 13.75 8.99365 13.75 9.25928C13.75 9.75732 13.3848 10.1143 12.8618 10.1143C12.6128 10.1143 12.3638 10.0063 12.2061 9.81543L11.3428 8.86914L10.7202 7.99756L10.8281 9.69922V13.3433C10.8281 13.9077 10.3799 14.3062 9.79883 14.3062Z"
  #                           class="">                          </path>
  #                       </svg>
  #                     </div>
  #                   </div>
  #                 </div>
  #               </div>
  #             </div>
  #           </div>
  #         </div>
  #       </div>
  #     </div>
  #   </div>
  #   """
  # end

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
          <dt :if={Map.has_key?(item, :title)} class="w-1/6 flex-none text-zinc-500"><%= item.title %></dt>
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
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
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
end
