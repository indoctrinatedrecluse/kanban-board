import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "content"]

  connect() {
    document.addEventListener("keydown", (e) => this.handleEscape(e))
  }

  disconnect() {
    document.removeEventListener("keydown", (e) => this.handleEscape(e))
  }

  open(event) {
    event.preventDefault()
    const cardId = event.currentTarget.dataset.cardId
    
    fetch(`/cards/${cardId}`, { 
      headers: { "Accept": "text/html" } 
    })
      .then((response) => response.text())
      .then((html) => {
        this.contentTarget.innerHTML = html
        this.element.classList.add("is-open")
        document.body.style.overflow = "hidden"
        
        // Setup form submission handler
        const form = this.contentTarget.querySelector("form")
        if (form) {
          form.addEventListener("submit", (e) => this.handleFormSubmit(e))
        }
      })
  }

  handleFormSubmit(event) {
    event.preventDefault()
    const form = event.target
    
    fetch(form.action, {
      method: form.method || "PATCH",
      headers: {
        "Accept": "text/vnd.turbo-stream.html, text/html",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: new FormData(form)
    })
      .then((response) => response.text())
      .then((html) => {
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        Turbo.parseAndDispatchAction(doc)
        this.close()
      })
  }

  close() {
    this.element.classList.remove("is-open")
    document.body.style.overflow = ""
    this.contentTarget.innerHTML = ""
  }

  closeOnBackdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.element.classList.contains("is-open")) {
      this.close()
    }
  }
}

