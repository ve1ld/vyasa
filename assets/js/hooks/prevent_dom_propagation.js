/*
 *
 */

// [4] @DEMO ERROR: this is how we are supposed to stop theh propagation, the event handling is working
// if you just do it on the marks display that isn't rendered from within the modal.
PreventEventPropagation = {
  mounted() {
    const selector = this.el.dataset.selector; // Get the selector from data attributes
    const eventName = this.el.dataset.eventName; // Get the event name from data attributes
    console.log("TRACE: NICE SEE ME", this.el.dataset);

    // Attach an event listener to the specified selector
    document.querySelectorAll(selector).forEach((form) => {
      form.addEventListener(eventName, (event) => {
        event.preventDefault(); // Prevent default submission
        event.stopPropagation(); // Stop the event from bubbling up
        console.log("TRACE: NICE SEE ME EVENT TO MODIFY:", event);
      });
    });
  },
};

export default PreventEventPropagation;
