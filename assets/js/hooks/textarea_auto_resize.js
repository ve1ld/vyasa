/**
 * This hook, if injected to a textarea, will automatically resize the
 * textarea height (bound by max height, if already defined).
 * */

const targetEvents = ["input", "focus", "click"];

export default TextareaAutoResize = {
  mounted() {
    console.log("!!! mounted TextareaAutoResize");
    this.handleInput();

    // Bind handleInput to maintain context
    this.handleInputBound = this.handleInput.bind(this);

    // Add event listeners correctly
    targetEvents.forEach((e) =>
      this.el.addEventListener(e, this.handleInputBound),
    );

    // watches for visibility changes:
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        const isTextAreaVisibleInViewport = entry.isIntersecting;
        if (isTextAreaVisibleInViewport) {
          this.handleInput(); // Call handleInput when textarea becomes visible
        }
      });
    });

    // watches for mutations on the element
    this.mutationObserver = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        const isDisabledAttrMutated =
          mutation.type === "attributes" &&
          mutation.attributeName === "disabled";
        if (isDisabledAttrMutated) {
          this.handleInput();
        }
      });
    });

    // Start observing:
    this.observer.observe(this.el);
    this.mutationObserver.observe(this.el, { attributes: true });
  },

  destroyed() {
    console.log("!!! destroyed TextareaAutoResize");

    // Prevent memory leaks by removing event listeners
    targetEvents.forEach((e) =>
      this.el.removeEventListener(e, this.handleInputBound),
    );

    // Disconnect observers:
    if (this.observer) {
      this.observer.disconnect();
    }

    if (this.mutationObserver) {
      this.mutationObserver.disconnect();
    }
  },

  /**
   * Adjusts the height of the textarea on input.
   */
  handleInput() {
    this.el.style.height = "auto"; // Reset height
    this.el.style.height = `${this.el.scrollHeight}px`; // Set height based on scrollHeight
    console.log("!!! Handling input", {
      elem: this.el,
      pxScrollHeight: this.el.scrollHeight,
    });
  },
};
