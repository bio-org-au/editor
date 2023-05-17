// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// import "@hotwired/turbo-rails";
// https://github.com/hotwired/turbo-rails - notes on disabling by default
import { Turbo } from "@hotwired/turbo-rails"
Turbo.session.drive = false
import "controllers"
import "jQuery"; // select2 needs this case-sensitive version of jQuery - "jquery" gives error
import "select2"; // this import first
import "dropdown";
import "fresh";
import "jquery-dateformat.min";
import "main";
import "new_search";
import "tabs";
import "typeahead_bundle";
import "typeaheads_for_author_duplicate_of";

import "typeaheads_for_instance_for_name_showing_reference_update";
import "typeaheads_for_instance_name";
import "typeaheads_for_instance_name_for_unpub_citation";
import "typeaheads_for_instance_reference";
import "typeaheads_for_instance_reference_excluding_current";
import "typeaheads_for_instance_synonymy";

import "typeaheads_for_loader_batch_default_reference";
import "typeaheads_for_loader_name_parent";
import "typeaheads_for_orchids_parent";

import "typeaheads_for_reference_author";
import "typeaheads_for_reference_duplicate";
import "typeaheads_for_reference_parent";

import "typeaheads_for_name_author";
import "typeaheads_for_name_authors_by_abbrev";
import "typeaheads_for_name_base_author";
import "typeaheads_for_name_cultivar_parent";
import "typeaheads_for_name_cultivar_second_parent";
import "typeaheads_for_name_duplicate_of";
import "typeaheads_for_name_ex_author";
import "typeaheads_for_name_ex_base_author";
import "typeaheads_for_name_family";
import "typeaheads_for_name_hybrid_parent";
import "typeaheads_for_name_parent";
import "typeaheads_for_name_sanctioning_author";
import "typeaheads_for_name_second_parent";
import "typeaheads_for_name_workspace_parent_name";
import Rails from '@rails/ujs';

Rails.start();


console.log($); // ok


if (debugSwitch === true) {
  window.onload = function() {
    console.log('window loaded via js/application.js');
  }

  $(document).on("turbo:load", () => {
    console.log('turbo! via javascript/application.js');
    console.log('Turbo.session.drive: ' + Turbo.session.drive);
  });
}

