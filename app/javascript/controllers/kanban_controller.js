import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["column"]

  dragstart(event) {
    this.draggedCard = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.draggedCard.dataset.cardId)
    this.draggedCard.classList.add("is-dragging")
  }

  dragend() {
    this.draggedCard?.classList.remove("is-dragging")
    this.draggedCard = null
  }

  dragover(event) {
    event.preventDefault()
    const column = event.currentTarget
    const afterElement = this.cardAfterPointer(column, event.clientY)

    if (!this.draggedCard) return

    if (afterElement) {
      column.insertBefore(this.draggedCard, afterElement)
    } else {
      column.appendChild(this.draggedCard)
    }
  }

  drop(event) {
    event.preventDefault()
    if (!this.draggedCard) return

    const column = event.currentTarget
    const position = [...column.querySelectorAll(".kanban-card")].indexOf(this.draggedCard) + 1

    fetch(`/cards/${this.draggedCard.dataset.cardId}/move`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({ column_id: column.dataset.columnId, position: position })
    })
  }

  cardAfterPointer(column, pointerY) {
    const cards = [...column.querySelectorAll(".kanban-card:not(.is-dragging)")]

    return cards.reduce((closest, child) => {
      const box = child.getBoundingClientRect()
      const offset = pointerY - box.top - box.height / 2

      if (offset < 0 && offset > closest.offset) {
        return { offset: offset, element: child }
      }

      return closest
    }, { offset: Number.NEGATIVE_INFINITY }).element
  }
}
