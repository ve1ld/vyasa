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
    this.floaterId = floaterId;
    this.floaterReferenceSelector = floaterReferenceSelector;
  },
  beforeUpdate() { // gets called synchronously, prior to update
    console.log("[floater] Triggerred floater::beforeUpdate()")
    const {
      floater,
      reference
    } = getRelevantElements(this.floaterId, this.floaterReferenceSelector);

    this.floater = floater;
    this.reference = reference;
    this.alignFloaterToRef()
  },
  updated() { // gets called when the elem changes
    console.log("[floater] Triggerred floater::updated()")
    const {
      floater,
      reference
    } = getRelevantElements(this.floaterId, this.floaterReferenceSelector);

    this.floater = floater;
    this.reference = reference;
  },
  alignFloaterToRef() {
    const canBeAligned = this.floater && this.reference
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

    computePosition(this.reference, this.floater, {
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
      Object.assign(this.floater.style, {
        left: `${x}px`,
        top: `${y}px`,
      });
    });

  }
}

/**
 * Selects relevant elements.
 *
 * It is expected that the floaterReference shall be a valid DOM query for node selections. ref: https://developer.mozilla.org/en-US/docs/Web/API/Document_object_model/Locating_DOM_elements_using_selectors
 * */
const getRelevantElements = (floaterId, floaterReferenceSelector) => {
  const floater = document.getElementById(floaterId)
  const reference = document.querySelector(floaterReferenceSelector)

  console.log("[floater] check relevant elements: ", {
    floaterId,
    floaterReferenceSelector,
    floater,
    reference,
  })

  return {
    floater,
    reference
  }
}


export default Floater;
