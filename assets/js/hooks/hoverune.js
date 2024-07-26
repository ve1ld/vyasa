import { computePosition, offset, inline, autoUpdate } from "floating-ui.dom.umd.min";

const findParent = (el, attr, stopper) => {
  // need identifier for marginoted content
  if (el && el.localName == "body") return null
  if (el && el.getAttribute(attr) == stopper) return el
  if (!el) return null
  return findParent(el.parentElement, attr, stopper)
}

function floatHoveRune({clientX, clientY}) {

  console.log("sting like a bees")
  const selection = window.getSelection()
  var getSelectRect = selection.getRangeAt(0).getBoundingClientRect()
  const virtualEl = {
    getBoundingClientRect() {
      return getSelectRect
    },
    contextElement: document.querySelector('#verses'),
  };
  const hoverune = document.getElementById("hoverune");

  computePosition(virtualEl, hoverune, {placement: 'top-end', middleware: [inline(getSelectRect.x, getSelectRect.y), offset(5)]}).then(({x, y}) => {
    // Position the floating element relative to the click
    hoverune.classList.remove("hidden")
      Object.assign(hoverune.style, {
      left: `${getSelectRect.x}px`,
      top: `${y}px`,
    })
  });

  // computePosition(virtualEl, hoverune, {placement: 'top-end', middleware: [inline(getSelectRect.x, getSelectRect.y), offset(5)]}).then(({x, y}) => {
  //   hoverune.classList.remove("hidden")
  //   Object.assign(hoverune.style, {
  //     left: `${getSelectRect.x}px`,
  //     top: `${y}px`,
  //   });
  // })
}

const findHook = el => findParent(el, "phx-hook", "HoveRune")
const findMarginote = el => findParent(el, "phx-hook", "MargiNote")
const findNode = el => el && el.getAttribute('node')
const forgeBinding = (el, attrs)  => attrs.reduce((acc, attr) => {
  acc[attr] = el.getAttribute(attr)
  return acc
}, {})
// const marginoteParent = el => findParent(el, "data-marginote", "parent")

export default HoveRune = {
  mounted() {
    const t = this.el
    window.addEventListener('click', ({ target }) => {
      var selection = window.getSelection()
      var getSelectRect = selection.getRangeAt(0).getBoundingClientRect();
      const getSelectText = selection.toString()
      //const validElem = findHook(target)
      // const isMarginote = findMarginote(target)
      const isNode = findNode(target)

      if (isNode) {
        binding = forgeBinding(target, ["node", "node_id", "field", "verse_id"])
        binding["selection"] = getSelectText
        this.pushEvent("bindHoveRune", {"binding": binding})


        computePosition(target, hoverune, {placement: 'top-end', middleware: [inline(getSelectRect.x, getSelectRect.y), offset(5)]}).then(({x, y}) => {
          hoverune.classList.remove("hidden")
          Object.assign(hoverune.style, {
            left: `${getSelectRect.x}px`,
            top: `${y}px`,
          });
        })

    }
      else {
        hoverune.classList.add("hidden")
      }
    })},

  updated() {
  }
}