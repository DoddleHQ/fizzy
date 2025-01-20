import { Controller } from "@hotwired/stimulus"

const MOVE_ITEM_DATA_TYPE = "x-fizzy/move"
const DIVIDER_ITEM_NODE_NAME = "LI"
const OVERLAP_THRESHOLD = 0.25

export default class extends Controller {
  static targets = [ "divider", "dragImage", "count" ]
  static classes = [ "installed", "dragging" ]
  static values = { startCount: Number, maxCount: Number }

  connect() {
    this.install()
  }

  install() {
    this.#moveDividerTo(this.startCountValue)
    this.dividerTarget.classList.add(this.installedClass)
  }

  configureDrag(event) {
    if (event.target == this.dividerTarget) {
      event.dataTransfer.dropEffect = "move"
      event.dataTransfer.setData(MOVE_ITEM_DATA_TYPE, event.target)
      event.dataTransfer.setDragImage(this.dragImageTarget, 0, 0)
      this.element.classList.add(this.draggingClass)
    }
  }

  acceptDrop(event) {
    if (event.dataTransfer.types.includes(MOVE_ITEM_DATA_TYPE)) {
      event.preventDefault()
    }
  }

  moveDivider(event) {
    if (event.target.nodeName == DIVIDER_ITEM_NODE_NAME) {
      const rect = this.dividerTarget.getBoundingClientRect()
      const distanceToTop = Math.abs(event.clientY - rect.top)
      const distanceToBottom = Math.abs(event.clientY - (rect.top + rect.height))
      const distanceToNearestEdge = Math.min(distanceToTop, distanceToBottom)
      const overlap = distanceToNearestEdge / rect.height

      if (overlap > OVERLAP_THRESHOLD) {
        this.#moveDividerTo(this.#items.indexOf(event.target))
      }
    }
  }

  drop() {
    this.element.classList.remove(this.draggingClass)
  }

  #moveDividerTo(index) {
    if (index <= this.maxCountValue) {
      if (this.#dividerIndex < index) {
        this.#positionDividerAfter(index)
      } else if (this.#dividerIndex > index) {
        this.#positionDividerBefore(index)
      }
    }
  }

  #positionDividerBefore(index) {
    const position = Math.max(index, 1)
    this.#items[position].before(this.dividerTarget)
    this.countTarget.textContent = position
  }

  #positionDividerAfter(index) {
    const position = Math.min(index, this.#items.length - 1, this.maxCountValue)
    this.#items[position].after(this.dividerTarget)
    this.countTarget.textContent = position
  }

  get #items() {
    return Array.from(this.element.children)
  }

  get #dividerIndex() {
    return this.#items.indexOf(this.dividerTarget)
  }
}
