# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

pin "jQuery", to: "https://cdn.jsdelivr.net/npm/jquery@3.6.0/dist/jquery.js", preload: true
pin "select2", to: "https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.7/js/select2.min.js"
pin "debug", preload: true
pin "keyboard_nav", preload: true
pin "dropdown", preload: true
pin "run_tree_reports", preload: true
pin "instance_note_edit", preload: true
pin "add_new_row", preload: true
pin "menu_ops", preload: true
pin "unconfirmed_action_link_click", preload: true
pin "name_rank_id_changed", preload: true
pin "loader_bulk_show_stats_ops", preload: true
pin "name_delete_form_submit", preload: true
pin "click_search_result_checkbox", preload: true
pin "copy_instance_for_name", preload: true
pin "cancel_link_click", preload: true
pin "copy_name_form_enter", preload: true
pin "create_copy_of_name_click", preload: true
pin "batch_submit", preload: true
pin "confirm_name_refresh_children_button_click", preload: true
pin "refresh_page_link_click", preload: true
pin "copy_instance_link_clicked", preload: true
pin "show_record_was_deleted", preload: true
pin "cancel_new_record", preload: true
pin "position_on_the_right", preload: true
pin "set_dependents", preload: true
pin "change_name_category_on_edit_tab", preload: true

pin "details_focus_on_field", to: "details/focus_on_field.js", preload: true
pin "utilities_page_load_performance", to: "utilities/page_load_performance.js", preload: true
pin "tree_refresh_tree_tab_refresh_page", to: "tree/refresh_tree_tab_refresh_page.js", preload: true
pin "tree_load_report", to: "tree/load_report.js", preload: true
pin "tree_init_dist_select", to: "tree/init_dist_select.js", preload: true
pin "tree_markdown", to: "tree/markdown.js", preload: true

pin "load_check_synonymy_report", preload: true
pin "search_result_focus", preload: true
pin "query_options", preload: true
pin "jquery-dateformat.min", preload: true
pin "new_search", preload: true
pin "tabs", preload: true
pin "typeaheads_send", to: "typeaheads/send.js", preload: true
pin "typeahead_bundle"
pin "bloodhound", to: "https://cdn.jsdelivr.net/npm/typeahead.js@0.11.1/dist/bloodhound.min.js"
pin "typeahead", to: "https://cdn.jsdelivr.net/npm/typeahead.js@0.11.1/dist/typeahead.bundle.min.js"

pin "typeaheads_for_author_duplicate_of", to: "typeaheads/for_author/duplicate_of.js"

pin "typeaheads_for_instance_for_name_showing_reference_update",
    to: "typeaheads/for_instance/for_name_showing_reference_update.js"
pin "typeaheads_for_instance_name", to: "typeaheads/for_instance/name.js"
pin "typeaheads_for_instance_name_for_unpub_citation", to: "typeaheads/for_instance/name_for_unpub_citation.js"
pin "typeaheads_for_instance_reference", to: "typeaheads/for_instance/reference.js"
pin "typeaheads_for_instance_reference_profile_v2", to: "typeaheads/for_instance/reference_profile_v2.js"
pin "typeaheads_for_instance_reference_excluding_current", to: "typeaheads/for_instance/reference_excluding_current.js"
pin "typeaheads_for_instance_synonymy", to: "typeaheads/for_instance/synonymy.js"
pin "typeaheads_for_instance_product_item_config", to: "typeaheads/for_instance/name_for_product_item_config.js"

pin "typeaheads_for_loader_batch_default_reference", to: "typeaheads/for_loader_batch/default_reference.js"
pin "typeaheads_for_loader_name_parent", to: "typeaheads/for_loader_name/parent.js"
pin "typeaheads_for_loader_name_match_intended_tree_parent_name", to: "typeaheads/for_loader_name_match/intended_tree_parent_name.js"

pin "typeaheads_for_reference_author", to: "typeaheads/for_reference/author.js"
pin "typeaheads_for_reference_duplicate", to: "typeaheads/for_reference/duplicate.js"
pin "typeaheads_for_reference_parent", to: "typeaheads/for_reference/parent.js"

pin "typeaheads_for_name_authors_by_abbrev", to: "typeaheads/for_name/authors_by_abbrev_bloodhound.js"
pin "typeaheads_for_name_author", to: "typeaheads/for_name/author.js"
pin "typeaheads_for_name_base_author", to: "typeaheads/for_name/base_author.js"
pin "typeaheads_for_name_cultivar_parent", to: "typeaheads/for_name/cultivar_parent.js"
pin "typeaheads_for_name_cultivar_second_parent", to: "typeaheads/for_name/cultivar_second_parent.js"
pin "typeaheads_for_name_duplicate_of", to: "typeaheads/for_name/duplicate_of.js"
pin "typeaheads_for_name_ex_author", to: "typeaheads/for_name/ex_author.js"
pin "typeaheads_for_name_ex_base_author", to: "typeaheads/for_name/ex_base_author.js"
pin "typeaheads_for_name_family", to: "typeaheads/for_name/family.js"
pin "typeaheads_for_name_hybrid_parent", to: "typeaheads/for_name/hybrid_parent.js"
pin "typeaheads_for_name_parent", to: "typeaheads/for_name/parent.js"
pin "typeaheads_for_name_sanctioning_author", to: "typeaheads/for_name/sanctioning_author.js"
pin "typeaheads_for_name_second_parent", to: "typeaheads/for_name/second_parent.js"
pin "typeaheads_for_name_workspace_parent_name", to: "typeaheads/for_name/workspace_parent_name.js"

pin "markdown_it_sub_min", to: "https://cdn.jsdelivr.net/npm/markdown-it-sub/dist/markdown-it-sub.min.js"
pin "markdown_it_sup_min", to: "https://cdn.jsdelivr.net/npm/markdown-it-sup/dist/markdown-it-sup.min.js"
pin "markdown_it_min", to: "https://cdn.jsdelivr.net/npm/markdown-it/dist/markdown-it.min.js"
pin "simplemde_min", to: "https://cdn.jsdelivr.net/simplemde/latest/simplemde.min.js"
pin "simple_mde_wysiwyg", preload: true

pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.0.4-3/lib/assets/compiled/rails-ujs.js"

pin "prompt_form_save", preload: true
