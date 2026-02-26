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
# Every search starts with a parsed request.
# You can also create a parsed request in the console.
# Try this from the console:
#   parsed_request = Search::ParsedRequest.new({ "query_target"=>"name",
#   "query_string"=>
#   "is-orth-var-and-sec-ref-first: limit: 2" })
class Search::ParsedRequest
  attr_reader :show_instances,
              :canonical_query_string,
              :common_and_cultivar,
              :count,
              :count_allowed,
              :defined_query,
              :defined_query_arg,
              :id,
              :include_common_and_cultivar_session,
              :limit,
              :limited,
              :offset,
              :offsetted,
              :instance_offset,
              :list,
              :order,
              :order_instances_by_page,
              :params,
              :query_string,
              :query_target,
              :target_table,
              :target_button_text,
              :target_model,
              :user,
              :where_arguments,
              :order_instance_query_by_page,
              :default_order_column,
              :default_query_directive,
              :include_instances,
              :include_instances_class,
              :default_query_scope,
              :apply_default_query_scope,
              :original_query_target,
              :original_query_target_for_display,
              :print,
              :display,
              :show_loader_name_comments,
              :show_profiles,
              :note_to_user

  DEFAULT_LIST_LIMIT = 100
  SIMPLE_QUERY_TARGETS = {
    "author" => "author",
    "authors" => "author",
    "instance" => "instance",
    "instances" => "instance",
    "name" => "name",
    "names" => "name",
    "reference" => "reference",
    "references" => "reference",
    "ref" => "reference",
    "loader_batch" => "loader batch",
    "loader_batches" => "loader batch",
    "batch_stacks" => "batch stack",
    "loader_name" => "loader name",
    "loader_names" => "loader name",
    "batch_review" => "batch review",
    "batch_reviews" => "batch review",
    "batch_review_period" => "batch review period",
    "batch_review_periods" => "batch review period",
    "user" => "users",
    "users" => "users",
    "organisation" => "org",
    "organisations" => "org",
    "org" => "org",
    "orgs" => "org",
    "batch_reviewer" => "batch reviewer",
    "batch_reviewers" => "batch reviewer",
    "bulk_processing_log" => "bulk processing log",
    "bulk_processing_logs" => "bulk processing log",
  }.freeze

  TARGET_MODELS = {
    "author" => "Author",
    "instance" => "Instance",
    "name" => "Name",
    "reference" => "Reference",
    "loader batch" => "Loader::Batch",
    "batch stack" => "Loader::Batch::Stack",
    "loader name" => "Loader::Name",
    "batch review" => "Loader::Batch::Review",
    "batch reviewer" => "Loader::Batch::Reviewer",
    "batch review period" => "Loader::Batch::Review::Period",
    "users" => "User",
    "org" => "Org",
    "bulk processing log" => "BulkProcessingLog",
  }.freeze

  TARGET_MODEL_SUPPORTS_PRINT_DIRECTIVE = %w[Loader::Name Instance]

  DEFAULT_QUERY_DIRECTIVES = {
    "author" => "name-or-abbrev:",
    "instance" => "name:",
    "name" => "sort_name:",
    "reference" => "citation:",
    "loader batch" => "name:",
    "batch stack" => "name:",
    "loader name" => "simple-name:",
    "batch review" => "name:",
    "batch reviewer" => "name:",
    "batch review period" => "name:",
    "users" => "user-name:",
    "org" => "name_or_abbrev:",
    "bulk processing log" => "log-entry:",
    "profile item" => "show-profiles:"
  }.freeze

  DEFAULT_ORDER_COLUMNS = {
    "author" => "name",
    "instance" => "id",
    "name" => "sort_name",
    "reference" => "citation",
    "loader batch" => "name",
    "batch stack" => "order_by",
    "loader name" => "sort_key, seq",
    "batch review" => "name",
    "batch reviewer" => "id",
    "batch review period" => "name",
    "users" => "user_name",
    "org" => "name",
    "bulk processing log" => " logged_at desc ",
  }.freeze

  INCLUDE_INSTANCES_FOR = %w[name reference]

  INCLUDE_INSTANCES_CLASS = {
    "name" => "Search::OnName::WithInstances",
    "references" => "Search::OnName::WithInstances",
  }.freeze

  ALLOW_SHOW_INSTANCES_TARGETS = %w[names name references reference]

  TRIM_RESULTS = {
    "loader name" => true,
  }.freeze

  ADDITIONAL_NON_PREPROCESSED_TARGETS = ["activity",
                                         "references_shared_names",
                                         "references_with_novelties",
                                         "references_names_full_synonymy",
                                         "references, names, full synonymy",
                                         "references with instances",
                                         "references_with_instances",
                                         "references + instances",
                                         "references with novelties",
                                         "references_with_novelties",
                                         "references, accepted names for id",
                                         "references_accepted_names_for_id",
                                         "instance is cited",
                                         "instance_is_cited",
                                         "instance is cited by",
                                         "instance_is_cited_by",
                                         "audit"]

  PREPROCESSING_TARGETS = {
    "loader_names" => "preprocess_loader_names",
  }

  SHOW_INSTANCES = "show-instances:"

  def initialize(params)
    @params = params
    @note_to_user = ''
    @query_string = canonical_query_string
    @query_string = @query_string.gsub(/  */, " ") unless @query_string.blank?
    @query_target = (@params["canonical_query_target"] || "").strip.downcase
    @user = @params[:current_user]
    @original_query_target = @query_target
    @default_query_scope = ""
    @apply_default_query_scope = false
    @original_query_target = @query_target
    parse_request
    @count_allowed = true
  end

  def debug(s)
    Rails.logger.debug("Search::ParsedRequest #{s}")
  end

  def inspect
    "Parsed Request: count: #{@count}; list: #{@list};
    defined_query: #{@defined_query}; where_arguments: #{@where_arguments},
    defined_query_args: #{@defined_query_args};
    query_target: #{@query_target};
    common_and_cultivar: #{@common_and_cultivar};
    limited: #{@limited};
    limit: #{@limit};
    offsetted: #{@offsetted};
    offset: #{@offset};
    include_common_and_cultivar_session
    : #{@include_common_and_cultivar_session};"
  end

  def parse_request
    unused_qs_tokens = normalise_query_string.split(/ /)
    parsed_defined_query = Search::ParsedDefinedQuery.new(@query_target)
    @defined_query = parsed_defined_query.defined_query
    @target_button_text = parsed_defined_query.target_button_text
    unused_qs_tokens = parse_count_or_list(unused_qs_tokens)
    unused_qs_tokens = parse_print_or_display(unused_qs_tokens)
    unused_qs_tokens = parse_limit(unused_qs_tokens)
    unused_qs_tokens = parse_instance_offset(unused_qs_tokens)
    unused_qs_tokens = parse_offset(unused_qs_tokens)
    unused_qs_tokens = preprocess_target(unused_qs_tokens)
    unused_qs_tokens = parse_target(unused_qs_tokens)
    unused_qs_tokens = parse_common_and_cultivar(unused_qs_tokens)
    unused_qs_tokens = inflate_show_instances_abbrevs(unused_qs_tokens)
    unused_qs_tokens = parse_show_instances(unused_qs_tokens)
    unused_qs_tokens = parse_order_instances(unused_qs_tokens)
    unused_qs_tokens = parse_view(unused_qs_tokens)
    unused_qs_tokens = parse_show_profiles(unused_qs_tokens)
    check_print_is_allowed
    @where_arguments = unused_qs_tokens.join(" ")
  end

  # Before splitting on spaces, make sure every colon has at least 1 space
  # after it.
  # Convert multiplication sign to x.
  def normalise_query_string
    if @query_string.blank?
      ""
    else
      @query_string.strip.gsub(":", ": ").gsub(":  ", ": ")
    end
  end

  def parse_count_or_list(tokens)
    if tokens.blank? then default_list_and_count
    elsif tokens.first =~ /\Acount\z/i
      tokens = tokens.drop(1)
      counting
    elsif tokens.first =~ /\Alist\z/i
      tokens = tokens.drop(1)
      listing
    else
      default_list_and_count
    end
    tokens
  end

  def parse_print_or_display(tokens)
    @print = false
    if tokens.include?("print:")
      confirm_valid_print_directive(tokens)
      @print = true
      tokens.delete_if { |x| x.match(/print:/) }
    end
    @show_loader_name_comments = false
    if tokens.include?("print-with-comments:")
      confirm_valid_print_with_comments_directive(tokens)
      @print = true
      @show_loader_name_comments = true
      tokens.delete_if { |x| x.match(/print-with-comments:/) }
    end
    @display = !@print
    tokens
  end

  def confirm_valid_print_directive(tokens)
    force_max_one_print_directive(tokens)
    raise 'Error: the print: directive has an argument, please remove the argument' if print_directive_has_arg?(tokens)
  end

  def confirm_valid_print_with_comments_directive(tokens)
    force_max_one_print_with_comments_directive(tokens)
    raise 'Error: the print-with-comments: directive has an argument, please remove the argument' if print_with_comments_directive_has_arg?(tokens)
  end

  def force_max_one_print_directive(tokens)
    raise 'Error: more than one print directive - please review and try again' if tokens.count('print:') > 1
  end

  def force_max_one_print_with_comments_directive(tokens)
    raise 'Error: more than one print-with-comments directive - please review and try again' if tokens.count('print-with-comments:') > 1
  end

  def print_directive_has_arg?(tokens)
    return false if tokens.last == 'print:'
    tokens[tokens.index("print:")+1].match(/:\z/).blank?
  end

  def print_with_comments_directive_has_arg?(tokens)
    return false if tokens.last == 'print-with-comments:'
    tokens[tokens.index("print-with-comments:")+1].match(/:\z/).blank?
  end

  def default_to_display_not_print
    @print = false
    @display = !@print
  end

  def default_list_and_count
    @list = true
    @count = !@list
  end

  def counting
    @count = true
    @list = !@count
  end

  def listing
    @list = true
    @count = !@list
  end

  # TODO: Refactor - to avoid limit being confused with an ID.
  #       Make limit a field limit: 999
  def parse_limit(tokens)
    @limited = @list
    joined_tokens = tokens.join(" ")
    joined_tokens = if @list
                      apply_list_limit(joined_tokens)
                    else # count
                      remove_limit_for_count(joined_tokens)
                    end
    filter_bad_limit(joined_tokens).split(" ")
  end

  def apply_list_limit(joined_tokens)
    if joined_tokens =~ /limit: \d{1,}/i
      @limit = joined_tokens.match(/limit: (\d{1,})/i)[1].to_i
      joined_tokens = joined_tokens.gsub(/limit: *\d{1,}/i, "")
    else
      @limit = DEFAULT_LIST_LIMIT
    end
    joined_tokens
  end

  def remove_limit_for_count(joined_tokens)
    @limit = 0
    joined_tokens.gsub(/limit: *\d{1,}/i, "")
  end

  def filter_bad_limit(joined_tokens)
    if joined_tokens.match(/limit: *[^\s\\]{1,}/i).present?
      bad_limit = joined_tokens.match(/limit: *([^\s\\]{1,})/i)[1]
      raise "Invalid limit: #{bad_limit}"
    end
    joined_tokens
  end

  # TODO: Refactor - to avoid limit being confused with an ID.
  #       Make limit a field limit: 999
  def parse_offset(tokens)
    @offsetted = @list
    joined_tokens = tokens.join(" ")
    joined_tokens = apply_list_offset(joined_tokens) if @list
    filter_bad_offset(joined_tokens).split(" ")
  end

  # TODO: Refactor - to avoid limit being confused with an ID.
  #       Make limit a field limit: 999
  def parse_instance_offset(tokens)
    @instance_offsetted = @list
    joined_tokens = tokens.join(" ")
    joined_tokens = apply_list_instance_offset(joined_tokens) if @list
    filter_bad_instance_offset(joined_tokens).split(" ")
  end

  def apply_list_offset(joined_tokens)
    if joined_tokens =~ /offset: \d{1,}/i
      @offset = joined_tokens.match(/offset: (\d{1,})/i)[1].to_i
      joined_tokens = joined_tokens.gsub(/offset: *\d{1,}/i, "")
    else
      @offset = nil
      @offsetted = false
    end
    joined_tokens
  end

  def filter_bad_offset(joined_tokens)
    if joined_tokens.match(/offset: *[^\s\\]{1,}/i).present?
      bad_offset = joined_tokens.match(/offset: *([^\s\\]{1,})/i)[1]
      raise "Invalid offset: #{bad_offset}"
    end
    joined_tokens
  end

  def apply_list_instance_offset(joined_tokens)
    if joined_tokens =~ /instance-offset: \d{1,}/i
      @instance_offset = joined_tokens.match(/instance-offset: (\d{1,})/i)[1].to_i
      joined_tokens = joined_tokens.gsub(/instance-offset: *\d{1,}/i, "")
    else
      @instance_offset = nil
      @instance_offsetted = false
    end
    joined_tokens
  end

  def filter_bad_instance_offset(joined_tokens)
    if joined_tokens.match(/instance-offset: *[^\s\\]{1,}/i).present?
      bad_instance_offset = joined_tokens.match(/instance-offset: *([^\s\\]{1,})/i)[1]
      raise "Invalid instance offset: #{bad_instance_offset}"
    end
    joined_tokens
  end

  def parse_view(tokens)
    joined_tokens = tokens.join(" ")
    joined_tokens = joined_tokens.gsub(/view: *[A-Za-z_]+/i, "")
    joined_tokens.split(" ")
  end

  def preprocess_target(tokens)
    if PREPROCESSING_TARGETS.include?(@query_target)
      method = PREPROCESSING_TARGETS[@query_target]
      send(method)
    elsif SIMPLE_QUERY_TARGETS.include?(@query_target)
    elsif ADDITIONAL_NON_PREPROCESSED_TARGETS.include?(@query_target)
    elsif loader_batch_preprocessing?
    else
      throw "Unknown query target: #{@query_target}"
    end
    tokens
  end

  # TODO: this should be in the loader/name/ code
  # Note limitation of any-batch: - it does not override a default batch
  # Note limitation of the checks: doesn't care if result of search is in only
  # one batch.
  #
  # Note: default-batch is deliberately case-sensitive due to its more complex 
  # processing at this time.
  # Called via send
  def preprocess_loader_names
    result = loader_batch_preprocessing?
    unless @params["query_string"].match(/\bdefault-batch:/) ||
           @params["query_string"].match(/\bbatch-id:/i) ||
           @params["query_string"].match(/\bbatch-name:/i) ||
           @params["query_string"].match(/\bany-batch:/i) ||
           @params["query_string"].match(/[^-]id:/i) ||
           @params["query_string"].match(/\Aid:/i) ||
           @params["query_string"].match(/\bid-with-syn:/i) 
      @params["query_string"] = @params["query_string"].dup << ' any-batch:'
      @note_to_user = 'any-batch applied'
    end
  end

  # TODO: convert this procedural code that refers to specific models to model
  # code or to some sort of declaration
  # TODO: should be in loader/name code
  #
  # Also, clarify what this method is doing.
  # Users with review access to a batch go thru "then"
  # Users without review access to a batch go thru "else"
  def loader_batch_preprocessing?
    if ::Loader::Batch.user_reviewable(@params[:current_user].username).collect do |batch|
         batch.name.downcase.gsub(", ", " ").rstrip
       end.include?(@query_target.downcase.gsub("_", " ").rstrip)
      @default_query_scope = "batch-id: #{::Loader::Batch.id_of(@query_target.gsub('_', ' '))}"
      debug("here is @default_query_scope: #{@default_query_scope}")
      @target_button_text = @query_target
      @original_query_target = @query_target
      @query_target = "loader_names"
      @apply_default_query_scope = true
      true
    else
      false
    end
  end

  def parse_target(tokens)
    if @defined_query == false
      raise "Cannot parse target: #{@query_target}." unless SIMPLE_QUERY_TARGETS.key?(@query_target)

      @target_table = SIMPLE_QUERY_TARGETS[@query_target]
      @target_button_text = @target_table.capitalize.pluralize
      @original_query_target_for_display = @original_query_target.gsub("_", " ").capitalize
      @target_model = TARGET_MODELS[@target_table]
      @default_order_column = DEFAULT_ORDER_COLUMNS[@target_table]
      @default_query_directive = DEFAULT_QUERY_DIRECTIVES[@target_table]
      if INCLUDE_INSTANCES_FOR.include?(@target_table)
        @include_instances = true
        @include_instances_class = INCLUDE_INSTANCES_CLASS[@target_table]
      end

    end
    tokens
  end

  def check_print_is_allowed
    return unless @print

    unless TARGET_MODEL_SUPPORTS_PRINT_DIRECTIVE.include?(@target_model)
      raise "Error: #{@target_table.capitalize} doesn't support the print directive"
    end

    if @target_model == "Instance" && !@show_profiles
      raise "Error: the print: directive for instances requires the show-profiles: directive"
    end
  end

  def parse_common_and_cultivar(tokens)
    @common_and_cultivar = false
    @include_common_and_cultivar_session = \
      @params["include_common_and_cultivar_session"] ||
      @params["query_common_and_cultivar"] == "t"
    tokens
  end

  def parse_show_profiles(tokens)
    if tokens.include?("show-profiles:")
      @show_profiles = true
    else
      @show_profiles = false
    end
    tokens
  end

  def inflate_show_instances_abbrevs(tokens)
    tokens = inflate_token(tokens, "s-i:", SHOW_INSTANCES)
    tokens = inflate_token(tokens, "si:", SHOW_INSTANCES)
    inflate_token(tokens, "i:", SHOW_INSTANCES)
  end

  def inflate_token(tokens, abbrev_s, full_s)
    if tokens.include?(abbrev_s)
      tokens.map! { |x| x == abbrev_s ? full_s : x }
    end
    tokens
  end

  def parse_show_instances(tokens)
    if tokens.include?("show-instances:")
      show_instances_allowed?
      @show_instances = true
      @order_instances_by_page = false
      tokens.delete_if { |x| x.match(/show-instances:/) }
    elsif tokens.include?("show-instances-by-page:")
      show_instances_allowed?
      @show_instances = true
      @order_instances_by_page = true
      tokens.delete_if { |x| x.match(/show-instances-by-page:/) }
    else
      @show_instances = false
    end
    tokens
  end

  def show_instances_allowed?
    return if ALLOW_SHOW_INSTANCES_TARGETS.include?(@query_target)

    raise "The show-instances: directive is not supported for this query"
  end

  def parse_order_instances(tokens)
    if tokens.include?("page-sort:")
      @order_instance_query_by_page = true
      tokens.delete_if { |x| x.match(/page-sort:/) }
    else
      @order_instance_query_by_page = false
    end
    tokens
  end

  def canonical_query_string
    @params[:query_string] || @params[:query]
  end

  def trim_results?
    TRIM_RESULTS[@target_table].nil? ? false : true
  end
end
