/**
 * This hook intends to follow a relay / shim pattern.
 *
 * When registered, it should have an associated name of a different dom selector and an event.
 * What this will do is to listen to a click event, and trigger the click even in the target dom node, if that exists.
 *
 * There's scope to generify this beyond click events in the future.
 * */
ButtonClickRelayer = {
  mounted() {
    this.el.addEventListener("click", (e) => this.relayClickEvent(e));
  },
  relayClickEvent(e) {
    e.preventDefault();
    const { targetRelayId: targetId } = this.el.dataset;
    const targetButton = document.getElementById(targetId);
    if (targetButton) {
      targetButton.click();
    }
  },
};

export default ButtonClickRelayer;
