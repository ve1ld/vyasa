import { computePosition, offset, inline } from "floating-ui.dom.umd.min";

const findParent = (el, attr, stopper) => {
  // need identifier for marginoted content
  if (el && el.localName == "body") return null
  if (el && el.getAttribute(attr) == stopper) return el
  if (!el) return null
  return findParent(el.parentElement, attr, stopper)
}

const findHook = el => findParent(el, "phx-hook", "HoveRune")
const findMarginote = el => findParent(el, "phx-hook", "MargiNote")
const findNode = el => el && el.getAttribute('node')
const forgeBinding = (el, attrs)  => attrs.reduce((acc, attr) => {return acc.set(attr, el.getAttribute(attr))}, new Map())
// const marginoteParent = el => findParent(el, "data-marginote", "parent")

export default HoveRune = {
  mounted() {
    const t = this.el
    const hoverune = document.querySelector('#hoverune');
    window.addEventListener('click', ({ target }) => {
      const selection = window.getSelection()
      var getSelectRect = selection.getRangeAt(0).getBoundingClientRect();
      //const validElem = findHook(target)
      // const isMarginote = findMarginote(target)
      const isNode = findNode(target)

      if (isNode) {
        binding = forgeBinding(target, ["node", "node_id", "field"])
        binding = binding.set("selection", selection.toString())
        console.log(binding)

        computePosition(target, hoverune, {placement: 'top-end', middleware: [inline(getSelectRect.x, getSelectRect.y), offset(5)]}).then(({x, y}) => {
          hoverune.classList.remove("hidden")
          Object.assign(hoverune.style, {
            left: `${getSelectRect.x}px`,
            top: `${y}px`,
          });
        })
      }
      else
      {
        hoverune.classList.add("hidden")
      }
    //    if (marginoteParent(target)) return

      // if (!isMarginote) {
      //   console.log("not marginote yet")
      //   //this.pushEvent("hide-quoted-comment")
      // }

      if (!selection || selection == "") return

    //   t.classList.remove("hidden")
    //   if (t.parentElement.classList.contains("popover__content")) {
    //     this.pushEvent("quoted-text", {quoted: selection}, () => {
    //       t.parentElement.classList.add("popover--visible")
    //     })
    //   }
    })},

  updated() {
    // const marginoteParent = document.querySelector("[data-marginote='parent']")
    // const id = marginoteParent.getAttribute("data-marginote-id")
    // const marginote = document.getElementById(`marginote-id-${id}`)

    // if (!marginoteParent) return
    // if (marginote) {
    //   this.pushEvent("show-quoted-comment", {id: `marginote-id-${id}`}, () => {
    //     computePosition(marginote, marginoteParent, {
    //       middleware: [offset(10), autoPlacement()],
    //     }).then(({ x, y}) => {
    //       this.pushEvent("adjust-marginote", {top: `${y}px`, left: `${x}px`})
    //     })
    //   })
    // }
  }
}
