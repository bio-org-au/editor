#
# Tree Element Profile
module Tree::Element::Profile::Distribution::Validations
  extend ActiveSupport::Concern
  included do
    def self.dist_options
      DistEntry.all.sort do |a, b|
        a.sort_order <=> b.sort_order
      end.collect(&:display)
    end

    def self.cleanup_distribution_string(s)
      s = s.strip.chomp(",").split(",").collect { |s| s.strip }
           .sort_by { |s| Tree::Element.region_position(s) || 99 }.uniq.join(", ")
    end

    def self.validate_distribution_string(s)
      s.split(",").collect { |val| val.strip }.each do |val|
        raise %(empty distribution value, likely due to an unnecessary comma) if val.blank?
        raise %(Invalid distribution value: "#{val}") unless DistEntry.exists?(display: val.strip)
      end
      reject_duplicates(s)
    end

    def self.reject_duplicates(s)
      a = remove_bracketed_qualifiers(s)
          .split(",")
          .collect { |e| e = e.strip }
      dupe = a.detect { |e| a.count(e) > 1 }
      raise %(duplicate value: '#{dupe}') unless dupe.nil?
    end

    def self.remove_bracketed_qualifiers(s)
      s.gsub(/\([^)]*\)/, "")
    end

    # e.g. input dist_entry 'AR (native and naturalised)'
    #      get the sort_order for AR from dist_region
    def self.region_position(dist_entry)
      DistRegion.as_hash[dist_entry.split(" ").first]
    end
  end # includes
end
