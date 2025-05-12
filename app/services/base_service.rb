class BaseService

  include ActiveModel::Validations

  def initialize(params, options = nil)
    @params = params
    @options = options
    @logger = Rails.logger
  end

  def self.call(*args, **keywords, &block)
    service = new(*args, **keywords, &block)
    service.execute

    service
  end

  def self.new_call_transaction(*args, &block)
    service = new(*args, &block)

    ActiveRecord::Base.transaction(joinable: false) do
      service.execute
      raise ActiveRecord::Rollback if service.errors.any?
    end

    service
  end

  # Default execute method
  def execute
    raise NotImplementedError, "Subclasses must implement the `execute` method"
  end
end
