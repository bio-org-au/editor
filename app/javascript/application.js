// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// import "@hotwired/turbo-rails";
// https://github.com/hotwired/turbo-rails - notes on disabling by default
// import { Turbo } from "@hotwired/turbo-rails"
import "@hotwired/turbo-rails"
// Turbo.session.drive = false
import "controllers";
import "jQuery"; // select2 needs this case-sensitive version of jQuery - "jquery" gives error
import "select2"; // this import first
import "dropdown";
//import "fresh";
//// start of fresh replacements
import "debug";
import "search_result_focus";
import "keyboard_nav";
import "query_options";
//import "run_tree_reports";
import "instance_note_edit";
import "add_new_row";
import "menu_ops";
import "unconfirmed_action_link_click";
import "loader_bulk_show_stats_ops";
import "name_rank_id_changed";
import "name_delete_form_submit";
import "click_search_result_checkbox";
import "copy_instance_for_name";
import "cancel_link_click";
import "copy_name_form_enter";
import "create_copy_of_name_click";
import "batch_submit";
import "confirm_name_refresh_children_button_click";
import "refresh_page_link_click";
import "copy_instance_link_clicked";
import "show_record_was_deleted";
import "cancel_new_record";
import "position_on_the_right";
import "set_dependents";
import "change_name_category_on_edit_tab";
import "tree_refresh_tree_tab_refresh_page";
import "tree_init_dist_select";
import "tree_load_report";
import "tree_markdown";
import "load_check_synonymy_report";
// end of fresh replacements
import "details_focus_on_field";
import "utilities_page_load_performance";
import "jquery-dateformat.min";
import "new_search";
import "tabs";
import "typeahead_bundle";
import "typeaheads_for_author_duplicate_of";

import "typeaheads_for_instance_for_name_showing_reference_update";
import "typeaheads_for_instance_name";
import "typeaheads_for_instance_name_for_unpub_citation";
import "typeaheads_for_instance_reference";
import "typeaheads_for_instance_reference_profile_v2";
import "typeaheads_for_instance_reference_excluding_current";
import "typeaheads_for_instance_synonymy";

import "typeaheads_for_loader_batch_default_reference";
import "typeaheads_for_loader_name_parent";
import "typeaheads_for_loader_name_match_intended_tree_parent_name";

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

import "markdown_it_sub_min";
import "markdown_it_sup_min";
import "markdown_it_min";
import "simplemde_min";
import "simple_mde_wysiwyg";

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

