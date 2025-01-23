import { Controller } from "@hotwired/stimulus"

const MAX_ROWS = 25

export default class extends Controller {
  static targets = [ "cell", "item" ]
  static values = { date: String }

  cellTargetConnected(target) {
    const dt = new Date(target.dataset.datetime)
    target.classList.toggle("future", dt > new Date())
    target.classList.toggle("current-hour", this.#isCurrentHour(dt))
  }

  itemTargetConnected(target) {
    const dt = new Date(target.dataset.datetime)
    target.classList.toggle("out-of-range", !this.#dateIsToday(dt))
    target.style.gridRowStart = MAX_ROWS - dt.getHours()
  }

  #dateIsToday(dt) {
    const date = new Date(this.dateValue)
    return this.#sameDay(dt, date)
  }

  #isCurrentHour(dt) {
    const now = new Date()
    return this.#sameDay(dt, now) && dt.getHours() === now.getHours()
  }

  #sameDay(dt1, dt2) {
    return dt1.getYear() === dt2.getYear() &&
      dt1.getMonth() === dt2.getMonth() &&
      dt1.getDay() === dt2.getDay()
  }
}
