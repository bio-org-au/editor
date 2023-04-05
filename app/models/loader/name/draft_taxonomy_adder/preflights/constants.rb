#   Copyright 2022 Australian National Botanic Gardens
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
# Loader Name entity
module Loader::Name::DraftTaxonomyAdder::Preflights::Constants
  COUNT_CREATED = [1,0,0]
  COUNT_DECLINED = [0,1,0]
  COUNT_ERROR = [0,0,1]

  DECLINED = "<span class='firebrick'>Declined to add to draft</span>"
  ERROR = "<span class='red'>Error: failed to add to draft</span>"
  CREATED = "<span class='darkgreen'>Added to draft</span>"
end

