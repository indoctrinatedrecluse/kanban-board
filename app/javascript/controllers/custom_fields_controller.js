import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fields", "field"]

  addField(event) {
    event.preventDefault()

    const field = document.createElement("div")
    field.classList.add("modal-row")
    field.dataset.customFieldsTarget = "field"
    field.innerHTML = `
      <div class="modal-field">
        <input type="text" name="card[custom_fields][][key]" placeholder="Field Name">
      </div>
      <div class="modal-field">
        <input type="text" name="card[custom_fields][][value]" placeholder="Value">
      </div>
      <button type="button" data-action="custom-fields#removeField" class="modal-remove-btn">&times;</button>
    `
    this.fieldsTarget.appendChild(field)
  }

  removeField(event) {
    event.preventDefault()

    const field = event.target.closest("[data-custom-fields-target='field']")
    if (field) {
      field.remove()
    }
  }
}