import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  search(event) {
    const query = event.target.value.toLowerCase()
    const cards = document.querySelectorAll(".kanban-card")

    cards.forEach((card) => {
      const title = card.querySelector("h3").textContent.toLowerCase()
      const description = card.querySelector("p")?.textContent.toLowerCase() || ""
      const labels = Array.from(card.querySelectorAll(".labels span")).map(l => l.textContent.toLowerCase()).join(" ")

      const isVisible = title.includes(query) || description.includes(query) || labels.includes(query)
      card.style.display = isVisible ? "" : "none"
    })
  }
}