import { computePosition, offset, autoPlacement } from "floating-ui.dom.umd.min";

const findParent = (el, attr, stopper) => {
  if (el && el.localName == "body") return null
  if (el && el.getAttribute(attr) == stopper) return el
  if (!el) return null
  return findParent(el.parentElement, attr, stopper)
}

const findHook = el => findParent(el, "phx-hook", "HoveRune")
const findMarginote = el => findParent(el, "phx-hook", "MargiNote")
const marginoteParent = el => findParent(el, "data-marginote", "parent")

export default HoveRune = {
  mounted() {
    const t = this.el
    window.addEventListener('click', ({ target }) => {
      const selection = window.getSelection().toString()
      const validElem = findHook(target)
      const isMarginote = findMarginote(target)

      if (!target) {
        t.parentElement.classList.remove("popover--visible")
      }

      if (marginoteParent(target)) return

      if (!isMarginote) {
        this.pushEvent("hide-quoted-comment")
      }

      if (!selection || selection == "") return

      t.classList.remove("hidden")
      if (t.parentElement.classList.contains("popover__content")) {
        this.pushEvent("quoted-text", {quoted: selection}, () => {
          t.parentElement.classList.add("popover--visible")
        })
      }
    })
  },
  updated() {
    const marginoteParent = document.querySelector("[data-marginote='parent']")
    const id = marginoteParent.getAttribute("data-marginote-id")
    const marginote = document.getElementById(`marginote-id-${id}`)

    if (!marginoteParent) return
    if (marginote) {
      this.pushEvent("show-quoted-comment", {id: `marginote-id-${id}`}, () => {
        computePosition(marginote, marginoteParent, {
          middleware: [offset(10), autoPlacement()],
        }).then(({ x, y}) => {
          this.pushEvent("adjust-marginote", {top: `${y}px`, left: `${x}px`})
        })
      })
    }
  }
}
