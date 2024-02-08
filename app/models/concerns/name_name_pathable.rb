# frozen_string_literal: true

# Names can be in a classification tree
module NameNamePathable
  extend ActiveSupport::Concern

  def make_name_path
    path = ""
    path = parent.name_path if parent
    path += "/" + name_element.strip if name_element
  end

  def build_name_path
    self.name_path = make_name_path
  end

  def build_and_save_name_path
    build_name_path
    save!(touch: false) if changed?
    1
  end

  def refresh_name_paths
    @tally ||= 0
    build_name_path
    if changed?
      save!(touch: false)
      @tally += 1
    end
    children.each do |child|
      @tally += child.refresh_name_paths
    end
    @tally
  end
end
