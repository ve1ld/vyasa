PreventEventPropagation = {
  mounted() {
    const selector = this.el.dataset.selector; // Get the selector from data attributes
    const eventName = this.el.dataset.eventName; // Get the event name from data attributes

    // Attach an event listener to the specified selector
    document.querySelectorAll(selector).forEach((form) => {
      form.addEventListener(eventName, (event) => {
        event.preventDefault(); // Prevent default submission
        event.stopPropagation(); // Stop the event from bubbling up
      });
    });
  },
};

export default PreventEventPropagation;
