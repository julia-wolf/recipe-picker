import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { fallback: String }

  connect() {
    if (this.element.complete && this.element.naturalWidth === 0) {
      this.fallback()
    }
  }

  fallback() {
    this.element.src = this.fallbackValue
    this.element.removeAttribute("data-action")
  }
}
