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
# For operation of copying names
class Name::AsCopier < Name
  NAC = "Name::AsCopier"
  def copy_with_username(new_name_element, as_username)
    Rails.logger.debug("#{NAC}#copy with username
                       new_name_element: #{new_name_element}")
    raise "Copied record would have the same name." if new_name_element.eql?(name_element)

    new = dup
    new.name_element = new_name_element
    new.created_by = new.updated_by = as_username
    new.uri = new.source_system = new.source_id_string = nil
    new.source_id = nil
    new.lock_version = 0
    new.save!
    new.set_names!
    new.refresh_name_paths
    new
  end

  def copy_with_all_instances(new_name_element, as_username)
    Rails.logger.debug("#{NAC} copy_with_all_instances: start.")
    Rails.logger.debug("#{NAC} copy_with_all_instances:
                       instances: #{instances.size}.")
    Rails.logger.debug("#{NAC} copy_with_all_instances:
                       self.instances: #{instances.size}.")
    ok = false
    copied_name = nil
    Name.transaction do
      Rails.logger.debug("copy_with_all_instances: start transaction.")
      copied_name = copy_with_username(new_name_element, as_username)
      Rails.logger.debug("copy_with_all_instances:
                         name copied, id: #{copied_name.id}.")
      Rails.logger.debug("copy_with_all_instances: now, instances....")
      instances.each do |i|
        Rails.logger.debug("copy_with_all_instances: instance: #{i.id}")
        instance = Instance::AsCopier.find(i.id)
        Rails.logger.debug("copy_with_all_instances: instance
                           as copier: #{instance.id}")
        Rails.logger.debug("copy_with_all_instances: instance
                           as copier: #{instance.inspect}")
        Rails.logger.debug("copy_with_all_instances: instance
                           as copier: id:     #{instance.id}")
        Rails.logger.debug("copy_with_all_instances: instance
                           as copier: name id:#{instance.name_id}")
        Rails.logger.debug("copy_with_all_instances: instance
                           as copier: ref id: #{instance.reference_id}")
        instance.copy_with_new_name_id(copied_name.id, as_username)
        Rails.logger.debug("copy_with_all_instances: after
                           copying the instance.")
      end
      Rails.logger.debug("copy_with_all_instances:
                         after working on the instances.")
      ok = true
    end
    if ok
      Rails.logger.debug("All ok in copy_with_all_instances.")
    else
      Rails.logger.error("There was a problem in copy_with_all_instances.")
      raise("Name not copied")
    end
    copied_name
  end
end
