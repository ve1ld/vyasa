/**
 * Autofocuses on the textarea that the hook is applied to.
 * Just a client-side shortcut.
 * */
export default TextareaFocus = {
  mounted() {
    this.el.focus();
  },
};
