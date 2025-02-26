/**
 * {PseudoForm}
 *
 * This hook facilitates the capture of input values from "form elements" without resorting to
 * tradition form-submission mechanisms. This approach is useful to avoid the nested form problem -- wherein
 * nested forms lead to unintended behaviour because a submission event in a child form will get bubbled out (propagated)
 * to the parent, as per HTML-DOM spec and will cause the parent's submit to also be triggerred. This would mean that
 * without the user desiring it so, there will be a form submission. While there are ways to hack this, for example by
 * preventing the bubble propagation from happening, those solutions are not long-term, which brings us to
 * consider this hook as an alternative approach. By using this hook, we can effectively manage input values while keeping
 * components stateless and avoiding the complexities associated with nested forms.

 * **Why Nested Forms Are an Antipattern**: [perplexity-generated section]
 * - **Event Propagation Issues**: Nested forms can cause submit events to bubble up, leading to unintended submissions of parent forms.
 * - **Complexity**: Managing state and events across nested forms increases the complexity of your application, making it harder to maintain.
 * - **Accessibility Concerns**: Screen readers and assistive technologies may struggle with nested forms, potentially leading to a poor user experience.
 * - **HTML Specification**: The HTML specification does not support nested forms, which can lead to inconsistent behavior across different browsers.
 *
 * **Value of Stateless Function Components**: [perplexity-generated section]
 * - Using function components that do not rely on form state allows for greater composability and flexibility.
 * - It enables nesting of components without the constraints imposed by traditional form handling, allowing for cleaner and more maintainable code.
 * - This approach promotes reusability and modularity within your codebase, making it easier to build complex UIs without the overhead of managing form state.
 *
 * Overall Mechanism for this hook:
 * - The hook listens for a specified event on the element it is attached to.
 * - When the event is triggered, it captures the value of a designated input element.
 * - It then pushes an event to the LiveView server with the captured input value and any additional payload.
 *
 * Expected Dataset Parameters:
 * - `data-event-to-capture`: A string representing the type of event to listen for (e.g., "click").
 *   This allows flexibility in determining which user interaction will trigger the value capture.
 *
 * - `data-target-selector`: A CSS selector string that identifies the input element from which to capture
 *   the value. This makes the hook generic and reusable for different types of inputs (e.g., textareas,
 *   text inputs).
 *
 * - `data-event-name`: A string representing the name of the event to be pushed to the LiveView server.
 *   If not provided, it defaults to "submitPseudoForm".
 *
 * - `data-event-target`: A string representing the target for the event push. This should match the
 *   target LiveView or component that will handle the event on the server side.
 *
 * - `data-event-payload`: A JSON string representing any additional data you want to send along with
 *   the captured input value. This allows for more complex interactions without needing to modify
 *   component state externally. This is actually a static part of the eventual payload that the event needs to have, we shall merge this with the input that we will be reading.
 *
 * Example Usage:
 * <button
 *   phx-hook="PseudoForm"
 *   data-event-to-capture="click"
 *   data-target-selector="#input-id"
 *   data-event-name="mark::editMarkContent"
 *   data-event-target="targetLiveView"
 *   data-event-payload='{"additional_key": "additional_value"}'
 * >
 *   Submit
 * </button>
 *
 * NOTE: this currently only handles single-input fields. This hook may be extended to
 * handle a group of input fields following a similar approach; otherwise, we should fallback to
 * typical LiveView idioms that deal with how to handle forms.
 */

PseudoForm = {
  mounted() {
    const eventToCapture = this.el.getAttribute("data-event-to-capture");
    this.el.addEventListener(eventToCapture, (_event) => {
      const targetSelector = this.el.getAttribute("data-target-selector");
      const eventName =
        this.el.getAttribute("data-event-name") || "submitPseudoForm";
      const eventPayload = JSON.parse(
        this.el.getAttribute("data-event-payload") || "{}",
      );
      const eventTarget = this.el.getAttribute("data-event-target");
      const inputElement = document.querySelector(targetSelector);

      if (inputElement) {
        const value = inputElement.value; // Reads the current value of the input
        const finalPayload = {
          ...eventPayload,
          input: value.trim(),
        };
        console.info("Using a pseudoform", {
          eventName,
          eventTarget,
          eventPayload,
          value,
          finalPayload,
        });
        this.pushEventTo(eventTarget, eventName, finalPayload);
      } else {
        console.warn("Desired input element not found, params:", {
          targetSelector,
          eventName,
          eventTarget,
          eventPayload,
        });
      }
    });
  },
};

export default PseudoForm;
