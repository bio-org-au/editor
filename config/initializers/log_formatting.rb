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
class ActiveSupport::Logger::SimpleFormatter
  SEVERITY_TO_TAG_MAP     = { "DEBUG" => "meh", "INFO" => "fyi",
                              "WARN" => "hmm", "ERROR" => "wtf",
                              "FATAL" => "omg", "UNKNOWN" => "???" }.freeze
  SEVERITY_TO_COLOR_MAP   = { "DEBUG" => "0;37", "INFO" => "32",
                              "WARN" => "33", "ERROR" => "31", "FATAL" => "31",
                              "UNKNOWN" => "37" }.freeze
  USE_HUMOROUS_SEVERITIES = true

  def call(severity, time, _progname, msg)
    formatted_severity = if USE_HUMOROUS_SEVERITIES
                           format("%-3s", SEVERITY_TO_TAG_MAP[severity])
                         else
                           format("%-5s", severity)
                         end

    formatted_time =
      time.strftime("%Y-%m-%d %H:%M:%S.") << time.usec.to_s[0..2].rjust(3)
    color = SEVERITY_TO_COLOR_MAP[severity]

    "\033[0;37m#{formatted_time}\033[0m [\033[#{color}m#{formatted_severity}\
\033[0m] r6editor #{msg.strip} (pid:#{$PROCESS_ID})\n"
  end
end
