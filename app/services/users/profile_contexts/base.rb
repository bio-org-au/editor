class Users::ProfileContexts::Base

  attr_reader :user, :product

  def initialize(user)
    @user = user
    @product = "unknown"
    @logger = Rails.logger
  end

  def profile_view_allowed?
    false
  end

  def profile_edit_allowed?
    false
  end

  def instance_edit_allowed?
    false
  end

  #
  # Tabs
  #
  def copy_instance_tab(instance, row_type=nil)
    "tab_copy_to_new_reference" if instance.standalone? && row_type == "instance_as_part_of_concept_record"
  end

  def unpublished_citation_tab(_instance)
    "tab_unpublished_citation"
  end

  def synonymy_tab(_instance)
    "tab_synonymy"
  end
  #
  # Method missing checks
  #
  def method_missing(method_name, *args, &block)
    if respond_to_missing?(method_name)
      super
    else
      @logger.warn("Undefined method `#{method_name}` called on #{self.class.name}")
      nil
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    false
  end
end
