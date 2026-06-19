# frozen_string_literal: true

module Instances
  class ChangeNameService < BaseService
    def initialize(instance:, new_name_id:, username:,
      create_synonym: false, cites_id: nil, synonym_instance_type_id: nil)
      super({})
      @instance = instance
      @new_name_id = new_name_id.to_i
      @username = username
      @create_synonym = create_synonym
      @cites_id = cites_id
      @synonym_instance_type_id = synonym_instance_type_id
    end

    def execute
      ActiveRecord::Base.transaction do
        change_name
        create_synonym_instance if errors.none? && create_synonym?
        raise ActiveRecord::Rollback if errors.any?
      end
    end

    private

    def create_synonym?
      @create_synonym.to_s == "yes" || @create_synonym == true
    end

    def change_name
      new_name = Name.find(@new_name_id)

      if synonym_name_ids.include?(@new_name_id)
        return errors.add(:base, "#{new_name.full_name} is listed as a synonym of this instance.")
      end

      unless new_name.name_type_id == @instance.name.name_type_id &&
          new_name.name_rank_id == @instance.name.name_rank_id
        return errors.add(:base, "The selected name must be the same type and rank as the current name.")
      end

      @instance.name_change_permitted = true
      @instance.name_id = @new_name_id
      @instance.updated_by = @username
      @instance.save
      errors.merge!(@instance.errors) if @instance.errors.any?
    end

    # Add the selected name back as a synonym, citing the instance the user
    # chose. Mirrors the cites/cited_by shape built by
    # InstancesController#create_cites_and_cited_by -> #build_them:
    #   name_id      = cites.name.id
    #   cites_id     = cites.id
    #   cited_by_id  = cited_by.id          (this instance)
    #   reference_id = cited_by.reference.id
    # draft and the override flags fall through to their model defaults, exactly
    # as the controller path does for this form.
    def create_synonym_instance
      cites = Instance.find(@cites_id)
      synonym = Instance.new(
        name_id: cites.name_id,
        cites_id: cites.id,
        cited_by_id: @instance.id,
        reference_id: @instance.reference_id,
        instance_type_id: @synonym_instance_type_id
      )
      synonym.save_with_username(@username)
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.record.errors.full_messages.join(", "))
    rescue ActiveRecord::RecordNotUnique
      errors.add(:base, "A matching synonym already exists for this instance.")
    end

    def synonym_name_ids
      Instance.where(cited_by_id: @instance.id).where.not(cites_id: nil).pluck(:name_id)
    end
  end
end
