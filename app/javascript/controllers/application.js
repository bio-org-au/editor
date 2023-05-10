import { Application } from "@hotwired/stimulus"

const application = Application.start()

//import Rails from '@rails/ujs';

//Rails.start(); // errors


// Configure Stimulus development experience
application.debug = true
window.Stimulus   = application

export { application }
