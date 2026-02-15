// EmphasisManager handles the DOM emphasis and scrolling behavior independently
class EmphasisManager {
  constructor() {
    this.emphasizedDomNode = this.initEmphasizedNode();
    this.isFollowMode = false;
  }

  initEmphasizedNode() {
    const emphasizedChapterPreamble = this.emphasizeChapterPreamble();
    return {
      prev: null,
      current: emphasizedChapterPreamble,
    };
  }

  emphasizeChapterPreamble() {
    const preambleNode = document.querySelector("#chapter-preamble");
    if (!preambleNode) {
      console.warn("[EMPHASIZE], no preamble node found");
      return null;
    }

    preambleNode.classList.add("emphasized-verse");
    return preambleNode;
  }

  toggleFollowMode() {
    this.isFollowMode = !this.isFollowMode;
  }

  // Handles emphasis based on verse ID
  emphasizeVerseById(verseId) {
    if (!verseId) return;

    const targetDomId = `verse-${verseId}`;
    this.updateEmphasis(targetDomId);
  }

  // Handles emphasis based on time-based event
  emphasizeByTimeEvent(currentTimeMs, events) {
    if (!events) return;

    const activeEvent = events.find(
      (event) =>
        currentTimeMs >= event.origin &&
        currentTimeMs < event.origin + event.duration,
    );

    if (!activeEvent?.verse_id) return;

    this.emphasizeVerseById(activeEvent.verse_id);
  }

  updateEmphasis(targetDomId) {
    const { current: currDomNode } = this.emphasizedDomNode;
    const updatedEmphasizedDomNode = {};

    if (currDomNode) {
      currDomNode.classList.remove("emphasized-verse");
      updatedEmphasizedDomNode.prev = currDomNode;
    }

    const targetNode = document.getElementById(targetDomId);
    if (!targetNode) return;

    targetNode.classList.add("emphasized-verse");
    updatedEmphasizedDomNode.current = targetNode;

    if (this.isFollowMode) {
      this.scrollToNode(targetNode);
    }

    this.emphasizedDomNode = updatedEmphasizedDomNode;
  }

  scrollToNode(node) {
    node.focus();
    node.scrollIntoView({
      behavior: "smooth",
      block: "center",
    });
  }
}
