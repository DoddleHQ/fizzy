import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["time", "date", "datetime", "ago"]

  initialize() {
    this.timeFormatter = new Intl.DateTimeFormat(undefined, { timeStyle: "short" })
    this.dateFormatter = new Intl.DateTimeFormat(undefined, { dateStyle: "long" })
    this.dateTimeFormatter = new Intl.DateTimeFormat(undefined, { timeStyle: "short", dateStyle: "short" })
    this.agoFormatter = new AgoFormatter()
  }

  timeTargetConnected(target) {
    this.#formatTime(this.timeFormatter, target)
  }

  dateTargetConnected(target) {
    this.#formatTime(this.dateFormatter, target)
  }

  datetimeTargetConnected(target) {
    this.#formatTime(this.dateTimeFormatter, target)
  }

  agoTargetConnected(target) {
    this.#formatTime(this.agoFormatter, target)
  }

  #formatTime(formatter, target) {
    const dt = new Date(target.getAttribute("datetime"))
    target.textContent = formatter.format(dt)
    target.title = this.dateTimeFormatter.format(dt)
  }
}

class AgoFormatter {
  format(dt) {
    const now = new Date()
    const seconds = (now - dt) / 1000
    const minutes = seconds / 60
    const hours = minutes / 60
    const days = hours / 24
    const weeks = days / 7
    const months = days / (365 / 12)
    const years = days / 365

    if (years >= 1) return this.#pluralize("year", years)
    if (months >= 1) return this.#pluralize("month", months)
    if (weeks >= 1) return this.#pluralize("week", weeks)
    if (days >= 1) return this.#pluralize("day", days)
    if (hours >= 1) return this.#pluralize("hour", hours)
    if (minutes >= 1) return this.#pluralize("minute", minutes)

    return "Less than a minute ago"
  }

  #pluralize(word, quantity) {
    quantity = Math.floor(quantity)
    const suffix = (quantity === 1) ? "" : "s"
    return `${quantity} ${word}${suffix} ago`
  }
}
