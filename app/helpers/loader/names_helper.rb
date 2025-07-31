# frozen_string_literal: true

module Loader::NamesHelper
  def build_reason_to_disable(loader_name, matching_name)
    reason_to_disable = "[Radio button is disabled because "
    reason_to_disable += "matching name has no primary instance; " unless matching_name.has_primary_instance?
    reason_to_disable += "matching name is a duplicate; " if matching_name.duplicate?
    reason_to_disable += "this synonym has no type; " if loader_name.synonym_without_synonym_type?
    reason_to_disable += "match cannot be cleared; " unless loader_name.can_clear_matches?
    reason_to_disable += "]"
    reason_to_disable.sub!("; ]", "]")
    reason_to_disable
  end

  def ref_instance_choice?(loader_name, matching_name)
    loader_name.loader_name_matches.where(name_id: matching_name.id).first.instance_choice_confirmed
  end

  def capture_comment_distribution(search_result)
    @stored_distribution = search_result.distribution
    @stored_comment = search_result.comment
    @stored_id = search_result.id
    @stored_result = search_result
  end

  def clear_captured
    @stored_distribution = nil
    @stored_comment = nil
    @stored_id = nil
    @stored_result = nil
  end

  def first_record?
    @previous_record_type.blank?
  end

  def flush_captured_and_capture_next(search_result, give_me_focus, wd)
    if %w(accepted excluded in-batch-note).include?(search_result.record_type) then
      concat(render partial: "#{wd}/loader_name_record/show_captured", locals: {search_result: search_result, give_me_focus: give_me_focus})
      capture_comment_distribution(search_result)
      concat(render partial: "#{wd}/loader_name_record/white_space_row")
    elsif search_result.record_type == 'heading'
      concat(render partial: "#{wd}/loader_name_record/show_captured", locals: {search_result: search_result, give_me_focus: give_me_focus})
      clear_captured
    end
  end

  def first_family?
    @previous_family.blank?
  end

  def capture_family(search_result)
    @previous_family = search_result.family 
  end

  def will_show_family(white_space)
    @show_family = true
    @add_white_space_before_family = white_space == :show_white_space
  end

  def will_not_show_family
    @show_family = false
  end

  def family_has_changed?(search_result)
    @previous_family != search_result.family
  end

  def should_show_family_heading?(search_result)
    %w(accepted excluded heading).include?(search_result.record_type)
  end
end
