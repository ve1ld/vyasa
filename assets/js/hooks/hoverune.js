import {
  computePosition,
  offset,
  inline,
  autoUpdate,
} from "floating-ui.dom.umd.min";

const findParent = (el, attr, stopper) => {
  // need identifier for marginoted content
  if (el && el.localName == "body") return null;
  if (el && el.getAttribute(attr) == stopper) return el;
  if (!el) return null;
  return findParent(el.parentElement, attr, stopper);
};

function floatHoveRune({ clientX, clientY }) {
  const selection = window.getSelection();
  var getSelectRect = selection.getRangeAt(0).getBoundingClientRect();
  const virtualEl = {
    getBoundingClientRect() {
      return getSelectRect;
    },
    contextElement: document.querySelector("#verses"),
  };
  const hoverune = document.getElementById("hoverune");

  computePosition(virtualEl, hoverune, {
    placement: "top-end",
    middleware: [inline(getSelectRect.x, getSelectRect.y), offset(5)],
  }).then(({ x, y }) => {
    // Position the floating element relative to the click
    hoverune.classList.remove("hidden");
    Object.assign(hoverune.style, {
      left: `${getSelectRect.x}px`,
      top: `${y}px`,
    });
  });
}

const findMatchingSpan = ({ node_id, field }) => {
  // Early return if missing either criteria
  if (!node_id || !field) return null;

  // Find first span with both exact matches
  return document.querySelector(
    `span[node_id="${node_id}"][field="${field}"]`
  );
};

const findHook = (el) => findParent(el, "phx-hook", "HoveRune");
const findMarginote = (el) => findParent(el, "phx-hook", "MargiNote");
const findNode = (el) => el && el.getAttribute("node");
const forgeBinding = (el, attrs) =>
  attrs.reduce((acc, attr) => {
    acc[attr] = el.getAttribute(attr);
    return acc;
  }, {});
// const marginoteParent = el => findParent(el, "data-marginote", "parent")

export default HoveRune = {
  mounted() {
    const t = this.el;
    this.eventTarget = this.el?.dataset?.eventTarget;
    console.log("CHECK HOVERUNE", {
      dset: this.el.dataset,
    });

    this.handleEvent("bind::share", (bind) => {
      if ("share" in navigator) {
      // uses webshare api:
        window.shareUrl(bind.url);
      } else if ("clipboard" in navigator) {
        navigator.clipboard.writeText(bind.url);
      } else {
        alert("Here is the url to share: #{bind.url}");
      }

    });

    this.handleEvent("bind::jump", (bind) => {
      console.warn(bind)
      targetNode = findMatchingSpan(bind)
      if (targetNode) {
      targetNode.focus();
      targetNode.scrollIntoView({
        behavior: "smooth",
        block: "center",
      });
      }

    });
        const targetEvents = ["pointerdown", "pointerup"];
    targetEvents.forEach((e) =>
      window.addEventListener(e, ({ target }) => {
        var selection = window.getSelection();
        if (!selection || selection.rangeCount <= 0) {
          return;
        }

        var range = selection.getRangeAt(0);
        var getSelectRect = range.getBoundingClientRect();
        const getSelectText = selection.toString();
        const isNode = findNode(target);

        console.log("binding selected here!")
        console.log(selection)

        if (isNode) {
          binding = forgeBinding(target, [
            "node",
            "node_id",
            "text",
            "field",
            "verse_id",
          ]);
          binding["selection"] = getSelectText;
          console.log("CHECK HOVERUNE", {
            eventTarget: this.eventTarget,
            target: `#${this.eventTarget}`,
            payload: { binding: binding },
          });
          this.pushEvent("bind::to", {
            binding: binding,
            target: this.eventTarget
          });

          console.log(binding);

          computePosition(target, hoverune, {
            placement: "top-end",
            middleware: [inline(getSelectRect.x, getSelectRect.y), offset(5)],
          }).then(({ x, y }) => {
            hoverune.classList.remove("hidden");
            Object.assign(hoverune.style, {
              left: `${getSelectRect.x}px`,
              top: `${y}px`,
            });
          });
        } else {
          hoverune.classList.add("hidden");
        }
      }),
    );
  },

  updated() {},
};
