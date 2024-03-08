/*
 * Ideally generic hook for floating logic.
 */
Floater = {
  mounted() {
    console.log("[floater] floater mounted")
    console.log("[floater] dataset check: ", this.el.dataset)
    const {
      floaterId,
      floaterReferenceSelector
    } = this.el.dataset;
  },
  beforeUpdate() { // gets called synchronously, prior to update
    console.log("[floater] Triggerred floater::beforeUpdate()")
    const {
      floater,
      reference,
      fallback,
    } = this.getRelevantElements();

    // TODO: this is hardcoded to the media bridge, refactor when more sane.
    const offsetHeight = fallback.offsetHeight; // so pretend it's lower by this amount
    const isReferenceOutOfView = isElementOutOfViewport(reference, {top:0, bottom:offsetHeight, left: 0, right: 0})
    if (isReferenceOutOfView) {
      console.log("[floater] Reference is out of viewport, should use fallback", {
        floater,
        reference,
        fallback
      })
    }
    const target = isReferenceOutOfView ? fallback : reference
    this.alignFloaterToRef(floater, target);
  },
  updated() { // gets called when the elem changes
    console.log("[floater] Triggerred floater::updated()")
    const {
      floater,
      reference,
      fallback,
    } = this.getRelevantElements();
  },
  alignFloaterToRef(floater, reference) {
    const canBeAligned = floater && reference
    if(!canBeAligned) {
      console.log("[floater] Can't be aligned")
      return
    }

    const {
      computePosition,
      autoPlacement,
      shift,
      offset,
    } = window.FloatingUIDOM;

    computePosition(reference, floater, {
      placement: 'right',
      // NOTE: order of middleware matters.
      middleware: [
        autoPlacement({
          allowedPlacements: [
            "right",
            "top"
          ]
        }),
        shift({
          padding: 8,
          crossAxis: true,
        }),
        offset(6),
      ],
    }).then(({x, y}) => {
      console.log("[floater] computed coordinates:", {x, y})
      Object.assign(floater.style, {
        left: `${x}px`,
        top: `${y}px`,
      });
    });
  },
  getRelevantElements() {
    const {
      floaterId,
      floaterReferenceSelector,
      floaterFallbackReferenceSelector,
    } = this.el.dataset;
    const floater = document.getElementById(floaterId)
    const reference = document.querySelector(floaterReferenceSelector)
    const fallback = document.querySelector(floaterFallbackReferenceSelector)

    console.log("[floater] getRelevantElements", {
      floater,
      reference,
      fallback,
    })

    return {
      floater,
      reference,
      fallback,
    }

  }
}

// offset: more positive is more in that direction. so if left = 2 vs left = 3, then the second left is more left than the first left lol.
// offest is to be applied to the value of the rect so rect with offset top = 2 is as though the original left +2 in height
function isElementOutOfViewport(el, offsets = {top: 0, bottom:0, left: 0, right:0}) {
  if (!el) {
    console.log("[floater] el is null", el)

  }

  const rect = el.getBoundingClientRect();
  const { top, bottom, left, right } = offsets;

  return (
    rect.top + top < 0 ||
      rect.left + left < 0 ||
      rect.bottom + bottom > (window.innerHeight || document.documentElement.clientHeight) ||
      rect.right + right > (window.innerWidth || document.documentElement.clientWidth)
  );
}

export default Floater;
