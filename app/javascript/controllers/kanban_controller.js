import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["column"]

  connect() {
    this.draggedCard = null
    this.copiedCard = null
    this.originalColumn = null
    this.originalPosition = null
    this.setupKeyboardHandlers()
  }

  setupKeyboardHandlers() {
    document.addEventListener("keydown", (e) => this.handleKeyDown(e))
  }

  handleKeyDown(event) {
    if (event.ctrlKey || event.metaKey) {
      if (event.key === "c") {
        this.handleCopyCard(event)
      } else if (event.key === "v") {
        this.handlePasteCard(event)
      }
    }
  }

  handleCopyCard(event) {
    const selectedCard = document.querySelector(".kanban-card.is-selected")
    if (!selectedCard) return

    event.preventDefault()
    this.copiedCard = {
      id: selectedCard.dataset.cardId,
      columnId: selectedCard.closest(".card-list").dataset.columnId
    }
    selectedCard.classList.add("is-copied")
    setTimeout(() => selectedCard.classList.remove("is-copied"), 150)
  }

  handlePasteCard(event) {
    if (!this.copiedCard) return

    event.preventDefault()
    const targetColumn = document.querySelector(".card-list.is-paste-target") ||
                         document.querySelector(".kanban-column:hover .card-list")

    if (!targetColumn) return

    fetch(`/cards/${this.copiedCard.id}/duplicate`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({ target_column_id: targetColumn.dataset.columnId })
    })
  }

  selectCard(event) {
    document.querySelectorAll(".kanban-card").forEach((card) => {
      card.classList.remove("is-selected")
    })
    event.currentTarget.classList.add("is-selected")
  }

  dragstart(event) {
    this.draggedCard = event.currentTarget
    const cardList = this.draggedCard.closest(".card-list")

    // Track original position for same-column reordering detection
    this.originalColumn = cardList
    this.originalPosition = [...cardList.querySelectorAll(".kanban-card")].indexOf(this.draggedCard) + 1

    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.draggedCard.dataset.cardId)
    this.draggedCard.classList.add("is-dragging")
  }

  dragend() {
    if (this.draggedCard) {
      this.draggedCard.classList.remove("is-dragging")
      this.draggedCard.classList.remove("is-reordering")
      this.columnTargets.forEach((col) => col.classList.remove("is-drag-over"))
    }
    this.draggedCard = null
    this.originalColumn = null
    this.originalPosition = null
  }

  dragover(event) {
    event.preventDefault()
    const column = event.currentTarget
    const cardList = column.querySelector(".card-list")

    column.classList.add("is-drag-over")

    if (!this.draggedCard) return

    // Add reordering class if moving within same column
    const isSameColumn = this.originalColumn === cardList
    if (isSameColumn) {
      this.draggedCard.classList.add("is-reordering")
    } else {
      this.draggedCard.classList.remove("is-reordering")
    }

    const afterElement = this.cardAfterPointer(cardList, event.clientY)

    if (afterElement) {
      cardList.insertBefore(this.draggedCard, afterElement)
    } else {
      cardList.appendChild(this.draggedCard)
    }
  }

  dragleave(event) {
    if (event.target === event.currentTarget) {
      event.currentTarget.classList.remove("is-drag-over")
    }
  }

  drop(event) {
    event.preventDefault()
    event.currentTarget.classList.remove("is-drag-over")

    if (!this.draggedCard) return

    const column = event.currentTarget
    const cardList = column.querySelector(".card-list")
    const newPosition = [...cardList.querySelectorAll(".kanban-card")].indexOf(this.draggedCard) + 1

    // Check if position actually changed
    const positionChanged = this.originalColumn !== cardList || this.originalPosition !== newPosition

    // Add snap animation
    this.draggedCard.classList.add("is-snapping")
    setTimeout(() => {
      this.draggedCard?.classList.remove("is-snapping")
    }, 300)

    if (positionChanged) {
      fetch(`/cards/${this.draggedCard.dataset.cardId}/move`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ column_id: column.dataset.columnId, position: newPosition })
      })
    }
  }

  cardAfterPointer(cardList, pointerY) {
    const cards = [...cardList.querySelectorAll(".kanban-card:not(.is-dragging)")]

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