class Loader::Name::DistributionValidator
  attr_reader :dist
  attr_reader :allowed_regions
  attr_reader :dist_regions
  attr_reader :dist_qualifiers
  attr_reader :error

  # See also module Tree::Element::Profile::Distribution::Validations concern
  #
  # Parameters
  #
  # dist is the distribution string to be validated
  # e.g. "WA, SA"
  #
  # allowed_regions is an array of valid region names e.g ['WA', 'NT', 'SA'...]
  #   in canonical order
  #
  # you could build the allowed_regions array like this:
  #
  #   allowed_regions = DistRegion.all.order(:sort_order).collect(&:name)
  #
  # Example:
  #
  # pry(main)> DistributionValidator.new('WA, SA', allowed_regions).call       => true
  #
  def initialize(dist_s, allowed_regions)
    @dist_s = dist_s
    if dist_s.blank?
      @dist_regions = @dist_qualifiers = []
    else
      @allowed_regions = allowed_regions
      @dist_regions = dist_s&.gsub(/ *\([^)]*\)/, "")&.split(/, */)
      @dist_qualifiers = dist_s&.split(/, */)&.collect {|e| e.sub(/.*(\(.*\)).*/, '\1')}
    end
  end

  def dist_region_indexes
    @dist_regions.collect {|dist_name| @allowed_regions.index(dist_name)}
  end

  def validate
    return true if @dist_s.blank?

    dist_has_no_empty_entries &&
      dist_has_no_trailing_comma &&
      dist_regions_are_valid &&
      dist_regions_has_no_duplicates &&
      dist_regions_are_ordered_correctly &&
      dist_region_entries_are_all_valid
  end

  def dist_regions_are_valid
    @dist_regions.each do |reg|
      @error = "#{reg} is an unknown region in: #{@dist_s}"
      return false unless @allowed_regions.include?(reg)
    end
    @error = nil
    true
  end

  def dist_regions_has_no_duplicates
    if @dist_regions.length == @dist_regions.uniq.length
      true
    else
      @error = "Duplicate value in: #{@dist_s}"
      false
    end
  end

  def dist_regions_are_ordered_correctly
    if dist_region_indexes == dist_region_indexes.sort {|x,y| x <=> y}
      true
    else
      @error = "Regions not ordered correctly in: #{@dist_s}"
      false
    end
  end

  def dist_region_entries_are_all_valid
    @dist_s.split(/, */).each do |entry|
      dist_entry = DistEntry.find_by_display(entry)
      if dist_entry.nil?
        @error = "Invalid entry '#{entry}' in: #{@dist_s}"
        return false
      end
    end
    true
  end

  def dist_has_no_empty_entries
    if @dist_s.split(/, */).include?("")
      @error = "Empty entries aren't allowed in: #{@dist_s}"
      false
    else
      true
    end
  end

  def dist_has_no_trailing_comma
    if @dist_s.match(/, *\z/)
      @error = "Trailing commas aren't allowed in: #{@dist_s}"
      false
    else
      true
    end
  end
end

