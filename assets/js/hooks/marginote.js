import { computePosition, offset, autoPlacement } from "floating-ui.dom.umd.min";

const findParents = (el, parents = []) => {
  if (el && el.localName == "body") return parents
  if (el && el.getAttribute("phx-hook") == "Marginote") return findParents(el.parentElement, parents.concat([el]))
  if (!el) return parents
  return findParents(el.parentElement, parents)
}

export default MargiNote = {
  func: 0,
  mounted() {
    const t = this.el
    const marginoteParent = document.querySelector("[data-marginote='parent']")
    t.addEventListener("click", ev => {
      const selection = window.getSelection().toString()

      if (selection !== "") return
      ev.stopPropagation()

      if (!marginoteParent) return

      const parents = findParents(t.parentElement, []).map(f => f.id.replace("marginote-id-", ""))


      this.pushEvent("show-quoted-comment", {id: t.id, parents}, () => {
        computePosition(this.el, marginoteParent, {
          middleware: [offset(10), autoPlacement()],
        }).then(({ x, y}) => {
          this.pushEvent("adjust-marginote", {top: `${y}px`, left: `${x}px`})
        })
      })
    })
  },
}
