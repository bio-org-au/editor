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
class Loader::Batch::Bulk::JobLog
  def initialize(job_number,
                 log_payload,
                 logged_by)
    @job_number = job_number
    @log_payload = log_payload
    @logged_by = logged_by
  end

  def write
    entry = %(Job #<span title="Full job number: #{@job_number}">...#{@job_number.to_s[-4..-1] || @job_number}</span>: #{@log_payload})
    BulkProcessingLog.log(entry, "Bulk job for #{@logged_by}")
  end
end
