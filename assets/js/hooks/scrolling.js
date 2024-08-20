Scrolling = {
  mounted() {
    console.log("SCROLLING MOUNTED");
    this.handleEvent("scroll-to-top", this.handleScrollToTop);
  },
  handleScrollToTop() {
    window.scrollTo({ top: 0, behavior: "smooth" });
  },
};

export default Scrolling;
