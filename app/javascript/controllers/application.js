import { Application } from "@hotwired/stimulus"

const application = Application.start()

//import Rails from '@rails/ujs';

//Rails.start(); // errors


window.Stimulus   = application

export { application }
