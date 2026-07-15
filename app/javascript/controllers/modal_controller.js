import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "content"]

  connect() {
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundHandleEscape)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
  }

  open(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const cardId = event.currentTarget.dataset.cardId
    const columnId = event.currentTarget.dataset.columnId
    const modalUrl = event.currentTarget.dataset.modalUrl
    
    let url
    if (modalUrl) {
      url = modalUrl
    } else if (cardId) {
      url = `/cards/${cardId}`
    } else if (columnId) {
      url = `/columns/${columnId}`
    } else {
      return
    }
    
    fetch(url, { 
      headers: { "Accept": "text/html" } 
    })
      .then((response) => response.text())
      .then((html) => {
        this.contentTarget.innerHTML = html
        this.backdropTarget.classList.add("is-open")
        document.body.style.overflow = "hidden"
        
        // Setup form submission handler
        const form = this.contentTarget.querySelector("form")
        form?.addEventListener("submit", (e) => this.handleFormSubmit(e))
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
        if (html.trim().startsWith("<turbo-stream")) {
          Turbo.renderStreamMessage(html)
        }
        this.close()
      })
  }

  close() {
    this.backdropTarget.classList.remove("is-open")
    document.body.style.overflow = ""
    this.contentTarget.innerHTML = ""
  }

  closeOnBackdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.backdropTarget.classList.contains("is-open")) {
      this.close()
    }
  }
}

