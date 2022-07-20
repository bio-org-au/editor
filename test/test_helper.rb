# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# require 'simplecov'
# SimpleCov.start

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
# require File.expand_path("../../config/environment", __FILE__)
# require "rails/test_help"

# require "minitest"
# require "minitest/rails"
# require "minitest/unit"
require "mocha"
require "mocha/setup"
# require "mocha/mini_test"
require "webmock/minitest"
#
# https://thoughtbot.com/blog/stubbing-and-setting-expectations-on-http-requests-is-now-easy-with-webmock
# require 'webmock/test_unit'
include WebMock::API

# Uncomment for awesome colorful output
# require "minitest/pride"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors, with: :threads)
  # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  # After commenting the above line, these disappeared:
  #
  # $ grep -i circular tests4.log | tee circ4c
  # RuntimeError: Circular dependency detected while autoloading constant TreeVersionElement
  # ...
  # RuntimeError: Circular dependency detected while autoloading constant NameStatus
  # ...
  # RuntimeError: Circular dependency detected while autoloading constant NameTagName
  # ...
  # RuntimeError: Circular dependency detected while autoloading constant NameCategory
  # ...
  # RuntimeError: Circular dependency detected while autoloading constant DistRegion
  # RuntimeError: Circular dependency detected while autoloading constant Reference
  # RuntimeError: Circular dependency detected while autoloading constant Author
  # RuntimeError: Circular dependency detected while autoloading constant NameType
  # RuntimeError: Circular dependency detected while autoloading constant Namespace
  # RuntimeError: Circular dependency detected while autoloading constant NameTag
  # RuntimeError: Circular dependency detected while autoloading constant Comment
  # RuntimeError: Circular dependency detected while autoloading constant InstanceType
  # RuntimeError: Circular dependency detected while autoloading constant RefAuthorRole
  # RuntimeError: Circular dependency detected while autoloading constant RefType

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

def debug(string)
  # print "#{Time.now} - #{string} \n"
end

def standard_page_assertions
  standard_page_assertions_part_1
  standard_page_assertions_part_2
end

def standard_page_assertions_part_1
  assert page.has_selector?("#query-on"), "No query-on field"
  assert page.has_selector?("#search-field"), "No search-field"
  assert page.has_content?("© NSL"), message: "Page needs copyright notice."
end

def standard_page_assertions_part_2
  assert page.has_selector?("#search-button"), "Page has no #search-button"
  assert page.has_selector?("input#search-field"),
         "Page has no #search-field element"
  assert page.has_field?("query"), 'Page has no "query" field'
end

def sign_in
  debug "start sign_in"
  visit "/sign_in"
  debug "sign_in about to fill_in fields"
  fill_in("sign_in_username", with: "gclarke")
  fill_in("sign_in_password", with: "fred")
  click_button("Sign in")
  big_sleep
  visit "/"
  debug "end sign_in"
end

def sign_in_as_editor
  visit "/sign_in"
  fill_in("sign_in_username", with: "editor")
  fill_in("sign_in_password", with: "password")
  click_button("Sign in")
  big_sleep
  visit "/"
end

def sign_in_as_qaonly
  visit "/sign_in"
  fill_in("sign_in_username", with: "qaonly")
  fill_in("sign_in_password", with: "password")
  click_button("Sign in")
  big_sleep
  visit "/"
end

def sign_in_as_qaeditor
  visit "/sign_in"
  fill_in("sign_in_username", with: "qaeditor")
  fill_in("sign_in_password", with: "password")
  click_button("Sign in")
  big_sleep
  visit "/"
end

def sign_in_as_read_only_user
  visit "/sign_in"
  fill_in("sign_in_username", with: "reader")
  fill_in("sign_in_password", with: "password")
  click_button("Sign in")
  big_sleep
  visit "/"
end

def tiny_sleep
  sleep(0.01)
end

def little_sleep
  sleep(0.1)
end

def moderate_sleep
  sleep(0.1)
end

def big_sleep
  debug("start big_sleep")
  sleep(1.0)
  debug("end big_sleep")
end

def make_sure_details_are_showing
  debug "start make_sure_details_are_showing"
  found = false
  tries = 0
  until found || tries > 9
    tries += 1
    fill_in "search-field", with: tries.to_s if tries > 1
    found = search_results_with_details?
    puts "make_sure_details_are_showing is exhausted - bailing out" if tries > 8
  end
  debug "end make_sure_details_are_showing"
end

def search_results_with_details?
  return unless search_results?
  return true if details_are_showing?

  show_details
  debug "sleeping...."
  sleep(0.01)
  false
end

def search_results?
  results_selector = "tr.search-result.fresh
                     td.takes-focus.main-content a.show-details-link"
  page.has_selector?(results_selector)
end

def details_are_showing?
  details_selector = "tr.search-result.fresh.showing-details
                     td.takes-focus.main-content a.show-details-link"
  page.has_selector?(details_selector)
end

def show_details
  all("tr.search-result.fresh td.takes-focus.main-content a.show-details-link")
    .first.click
end

def wait_for(selector, max_tries = 5)
  found = false
  tries = 0
  until found || tries > max_tries
    tries += 1
    if page.has_selector?(selector)
      found = true
    else
      sleep(1)
    end
  end
end

def set_name_parent
  fill_in_typeahead("name-parent-typeahead",
                    "name_parent_id",
                    "Agenus",
                    names(:a_genus).id)
  find("#search-result-details h4").click
end

def set_name_second_parent_to_a_species
  fill_in_typeahead("name-second-parent-typeahead",
                    "name_second_parent_id",
                    "Aspecies",
                    names(:a_species).id)
  find("#search-result-details h4").click
end

def set_name_parent_to_a_species
  fill_in_typeahead("name-parent-typeahead",
                    "name_parent_id",
                    "Aspecies",
                    names(:a_species).id)
  find("#search-result-details h4").click
end

def set_name_parent_to_a_genus
  fill_in_typeahead("name-parent-typeahead",
                    "name_parent_id",
                    "Agenus",
                    names(:a_genus).id)
  find("#search-result-details h4").click
end

def configure_for_webkit
  # page.driver.block_unknown_urls if Capybara.default_driver == :webkit
end

def visit_home_page
  configure_for_webkit
  sign_in
  visit "/"
end

def visit_home_page_as_editor
  configure_for_webkit
  sign_in_as_editor
  visit "/"
end

def visit_home_page_as_qaonly
  configure_for_webkit
  sign_in_as_qaonly
  visit "/"
end

def visit_home_page_as_qaeditor
  configure_for_webkit
  sign_in_as_qaeditor
  visit "/"
end

def visit_home_page_as_read_only_user
  configure_for_webkit
  sign_in_as_read_only_user
  visit "/"
end

def load_new_scientific_name_form
  Timeout.timeout(Capybara.default_wait_time) do
    loop until page.evaluate_script("jQuery.active").zero?
  end
  select_from_menu(["New", "Scientific name"])
  find_link("New scientific name").click
  search_result_must_include_content("New scientific name")
  search_result_details_must_include_content("New Scientific Name")
end

def load_new_hybrid_formula_form
  Timeout.timeout(Capybara.default_wait_time) do
    loop until page.evaluate_script("jQuery.active").zero?
  end
  select_from_menu(["New", "Hybrid formula name"])
  find_link("New hybrid formula name").click
  search_result_must_include_content("New hybrid formula name")
  search_result_details_must_include_content(
    "New Scientific Hybrid Formula Name"
  )
end

def load_new_cultivar_hybrid_name_form
  select_from_menu(["New", "Cultivar hybrid name"])
  search_result_must_include_content("New cultivar hybrid name")
  search_result_details_must_include_content("New Cultivar Hybrid Name")
end

def load_new_cultivar_name_form
  select_from_menu(["New", "Cultivar name"])
  search_result_must_include_content("New cultivar name")
  search_result_details_must_include_content("New Cultivar Name")
end

def load_new_hybrid_formula_unknown_2nd_parent_form
  Timeout.timeout(Capybara.default_wait_time) do
    loop until page.evaluate_script("jQuery.active").zero?
  end
  select_from_menu(["New", "Hybrid formula unknown 2nd parent name"])
  search_result_must_include_link("New hybrid formula unknown 2nd parent name")
  search_result_details_must_include_content(
    "New Scientific Hybrid Formula Unknown 2nd Parent Name"
  )
end

def load_new_other_name_form
  select_from_menu(["New", "Other name"])
  search_result_must_include_content("New other name")
  search_result_details_must_include_content("New Other Name")
end

def load_new_author_form
  Timeout.timeout(Capybara.default_wait_time) do
    loop until page.evaluate_script("jQuery.active").zero?
  end
  select_from_menu(%w[New Author])
  search_result_must_include_link("New author")
  search_result_details_must_include_content("New Author")
end

def select_from_menu(link_texts)
  Timeout.timeout(Capybara.default_wait_time) do
    loop until page.evaluate_script("jQuery.active").zero?
  end
  link_texts.each do |link_text|
    find_link(link_text).click
  end
end

def save_new_record
  Capybara.match = :first
  find_button("Save").click
end

def save_edits
  Capybara.match = :first
  find_button("Save").click
end

def after_javascript_finishes
  Timeout.timeout(Capybara.default_wait_time) do
    loop until page.evaluate_script("jQuery.active").zero?
  end
end

def assert_successful_create_for(expected_contents, prohibited = [])
  after_javascript_finishes
  default = Capybara.default_wait_time
  Capybara.default_wait_time = 2
  inner_assert_successful_create_for(expected_contents, prohibited)
  Capybara.default_wait_time = default
end

def inner_assert_successful_create_for(expected_contents, prohibited)
  assert page.has_field?("search-field"), "No search field."
  make_sure_details_are_showing
  find("#search-result-details")
  assert_expected(expected_contents)
  assert_no_prohibited(prohibited)
end

def assert_expected(expected_contents)
  expected_contents.each do |expected_content|
    assert page.has_content?(expected_content),
           "assert_successful_create_for says:
           Missing expected content: #{expected_content}"
  end
end

def assert_no_prohibited(prohibited_contents)
  prohibited_contents.each do |prohibited_content|
    assert page.has_no_content?(prohibited_content),
           "assert_successful_create_for says:
           Missing prohibited content: #{prohibited_content}"
  end
end

def fill_in_typeahead(text_field_id, hidden_field_id,
                      text_to_enter, id_to_enter)
  using_wait_time 4 do
    fill_in(text_field_id, with: text_to_enter)
  end
  script = "document.getElementById('" + hidden_field_id + "')
           .setAttribute('type','text')"
  execute_script(script)
  using_wait_time 2 do
    fill_in(hidden_field_id, with: id_to_enter)
  end
end

def fill_in_author_typeahead(text_field = "sanctioning-author-by-abbrev",
                             id_field = "name_sanctioning_author_id",
                             author = authors(:bentham))
  fill_in_typeahead(text_field, id_field, author.abbrev, author.id)
end

def search_result_must_include_content(content, msg = nil)
  msg = "Search result content not found: '#{content}'" if msg.nil?
  after_javascript_finishes
  assert find("div#search-result-container").has_content?(content), msg
end

def search_result_must_include(link_text, msg = "Search result not found!")
  after_javascript_finishes
  assert find("div#search-result-container").has_link?(link_text), msg
end

def search_result_must_not_include(link_text, msg = "Search result found!")
  after_javascript_finishes
  assert find("div#search-result-container").has_no_link?(link_text), msg
end

def search_result_details_must_include_link(link_text, msg = nil)
  msg = "Expected details link not found!: #{link_text}" if msg.nil?
  after_javascript_finishes
  assert find("div#search-result-details").has_link?(link_text), msg
end

def search_result_details_must_include_button(button_text, msg = nil)
  msg = "Expected details button not found!: #{button_text}" if msg.nil?
  after_javascript_finishes
  assert find("div#search-result-details").has_button?(button_text), msg
end

def search_result_details_must_include_field(field_id, msg = nil)
  msg = "Expected details field not found!: #{link_text}" if msg.nil?
  after_javascript_finishes
  assert find("div#search-result-details").has_field?(field_id), msg
end

def search_result_details_must_not_include_field(field_id, msg = nil)
  msg = "Found field that should not be there!: #{link_text}" if msg.nil?
  after_javascript_finishes
  assert find("div#search-result-details").has_no_field?(field_id), msg
end

def search_result_details_must_not_include_link(link_text, msg = nil)
  msg = "Prohibited details link found!: #{link_text}" if msg.nil?
  after_javascript_finishes
  assert find("div#search-result-details").has_no_link?(link_text), msg
end

def search_result_details_must_not_include_button(button_text, msg = nil)
  msg = "Prohibited details button found!: #{button_text}" if msg.nil?
  after_javascript_finishes
  assert find("div#search-result-details").has_no_button?(button_text), msg
end

def search_result_summary_must_include_content(content, msg = nil)
  msg = "Search result summary content not found!" if msg.nil?
  after_javascript_finishes
  assert find("div#search-results-summary-container").has_content?(content), msg
end

def search_result_details_must_include_content(text, msg = nil?)
  msg = "Expected details content not found!: #{text}" if msg.nil?
  after_javascript_finishes
  assert find("div#search-result-details").has_content?(text), msg
end

def search_result_must_include_link(link, msg = nil)
  msg = "Search result content not found: '#{link}'" if msg.nil?
  after_javascript_finishes
  assert find("div#search-result-container").has_link?(link), msg
end

# See www.rubytutorial.io/how-to-test-an-autocomplete-with-rails
def try_typeahead_multi(field_id,
                        input_text,
                        expected,
                        which_suggestion = "first")
  fill_in(field_id, with: input_text)
  page.execute_script %{ $('##{field_id}').trigger("focus") }
  suggestion = find("##{field_id}").find(:xpath, ".//..")
                                   .all("div.tt-suggestion")
                                   .send(which_suggestion)
  assert_not_nil suggestion, "Should have found a suggestion."
  assert_equal expected, suggestion.text, "Expected: #{expected}."
end

# See www.rubytutorial.io/how-to-test-an-autocomplete-with-rails
def try_typeahead_single(field_id, input_text, expected)
  fill_in(field_id, with: input_text)
  page.execute_script %{ $('##{field_id}').trigger("focus") }

  suggestion = find("##{field_id}").find(:xpath, ".//..")
                                   .find("div.tt-suggestion")

  assert_not_nil suggestion, "No such suggestion: '#{expected}'"
  assert_equal expected, suggestion.text, "Expected: #{expected}."
end

def fill_in_text_field(field, value)
  using_wait_time 20 do
    fill_in(field, with: value)
  end
end

def fill_in_id_field(field, id)
  using_wait_time 20 do
    fill_in(field, with: id)
  end
end
