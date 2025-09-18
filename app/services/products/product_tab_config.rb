module Products
  class ProductTabConfig

    attr_reader :flag_config, :tabs_config

    def initialize
      @tabs_config = parse_tabs_config
      @flag_config = parse_flag_config
    end

    def tabs_for(model, active_flags)
      return [] if active_flags.nil?

      model_config = tabs_config[model.to_s]
      return [] unless model_config

      combined_tabs = []

      active_flags.each do |flag|
        flag_config = model_config[flag.to_s]
        if flag_config
          flag_tabs = flag_config.is_a?(Hash) ? flag_config['tabs'] : flag_config
          if flag_tabs
            combined_tabs.concat(flag_tabs.map(&:to_s))
          end
        end
      end

      if combined_tabs.empty?
        default_config = model_config['default'] || []
        default_tabs = default_config.is_a?(Hash) ? default_config['tabs'] : default_config
        combined_tabs = (default_tabs || []).map(&:to_s)
      end

      combined_tabs.uniq
    end

    def enabled_models_for_flags(active_flags)
      return [] if active_flags.nil?

      enabled_models = []

      active_flags.each do |flag|
        models = flag_config[flag.to_s]
        if models
          enabled_models.concat(models.map(&:to_s))
        end
      end

      enabled_models.uniq
    end


    private

    def parse_flag_config
      JSON.parse(File.read(Rails.root.join('config/product_tabs/product_flag_configurations.json')))
    rescue JSON::ParserError, Errno::ENOENT
      {}
    end

    def parse_tabs_config
      JSON.parse(File.read(Rails.root.join('config/product_tabs/tabs.json')))
    rescue JSON::ParserError, Errno::ENOENT
      {}
    end
  end
end
