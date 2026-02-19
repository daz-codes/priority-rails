import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["backdrop", "modal", "mainPanel", "weeklyPanel", "monthlyPanel", "yearlyPanel", "yearlyDayPanel"];
  static values = { taskId: Number };

  connect() {
    this.selectedMonth = null;
  }

  toggle(event) {
    event.stopPropagation();
    const isHidden = this.modalTarget.hidden;
    if (isHidden) {
      this.open();
    } else {
      this.close();
    }
  }

  open() {
    this.resetPanels();
    this.backdropTarget.hidden = false;
    this.modalTarget.hidden = false;
  }

  close() {
    this.backdropTarget.hidden = true;
    this.modalTarget.hidden = true;
    this.resetPanels();
  }

  resetPanels() {
    this.mainPanelTarget.hidden = false;
    this.weeklyPanelTarget.hidden = true;
    this.monthlyPanelTarget.hidden = true;
    this.yearlyPanelTarget.hidden = true;
    this.yearlyDayPanelTarget.hidden = true;
    this.selectedMonth = null;
  }

  backToMain() {
    this.resetPanels();
  }

  backToYearlyMonths() {
    this.yearlyDayPanelTarget.hidden = true;
    this.yearlyPanelTarget.hidden = false;
  }

  selectDaily() {
    this.save({ recurrence_type: "daily", recurrence_day: null, recurrence_month: null });
  }

  showWeekly() {
    this.mainPanelTarget.hidden = true;
    this.weeklyPanelTarget.hidden = false;
  }

  selectWeekday(event) {
    const day = parseInt(event.currentTarget.dataset.day);
    this.save({ recurrence_type: "weekly", recurrence_day: day, recurrence_month: null });
  }

  showMonthly() {
    this.mainPanelTarget.hidden = true;
    this.monthlyPanelTarget.hidden = false;
  }

  selectMonthDay(event) {
    const day = parseInt(event.currentTarget.dataset.day);
    this.save({ recurrence_type: "monthly", recurrence_day: day, recurrence_month: null });
  }

  showYearly() {
    this.mainPanelTarget.hidden = true;
    this.yearlyPanelTarget.hidden = false;
  }

  selectYearMonth(event) {
    this.selectedMonth = parseInt(event.currentTarget.dataset.month);
    this.yearlyPanelTarget.hidden = true;
    this.yearlyDayPanelTarget.hidden = false;
  }

  selectYearDay(event) {
    const day = parseInt(event.currentTarget.dataset.day);
    this.save({ recurrence_type: "yearly", recurrence_day: day, recurrence_month: this.selectedMonth });
  }

  remove() {
    this.save({ recurrence_type: null, recurrence_day: null, recurrence_month: null });
  }

  save(params) {
    this.close();
    fetch(`/tasks/${this.taskIdValue}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
      },
      body: JSON.stringify({ task: params }),
    });
  }
}
