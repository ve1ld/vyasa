/**
 * This hook, if injected to a textarea, will automatically resize the
 * textarea height (bound by max height, if already defined).
 * */

export default TextareaAutoResize = {
  mounted() {
    this.handleInput();
  },
  handleInput() {
    this.el.style.height = "auto"; // Resets height to auto to shrink if needed
    this.el.style.height = `${this.el.scrollHeight}px`; // Sets height based on scrollHeight
  },
};
