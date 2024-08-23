/**
 * This hooks intercepts browser navigation actions and pipes it to server actions instead.
 * */
BrowserNavInterceptor = {
  mounted() {
    console.log("TRACE: Interceptor mounted");
    window.addEventListener("popstate", this.handleStatePop.bind(this));
  },
  destroyed() {
    console.log("TRACE: Interceptor destroyed");
    window.removeEventListener("popstate", this.handleStatePop.bind(this));
  },
  handleStatePop(e) {
    const { navTarget } = this.el.dataset;
    console.log("TRACE: Handle state pop", { navTarget, e });
    e.preventDefault();
    // this.pushEvent("BrowserNavInterceptor:nav", { nav_target: navTarget });
    this.pushEvent("BrowserNavInterceptor:nav", { nav_target: navTarget });
    if (e.state) {
      console.log(
        "TRACE: User navigated using the browser buttons. Detected using popstate event.",
      );
      // You can perform additional actions here, such as updating the UI
    }
  },
};

export default BrowserNavInterceptor;
