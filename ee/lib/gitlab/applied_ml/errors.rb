# frozen_string_literal: true

module Gitlab
  module AppliedMl
    module Errors
      BaseError = Class.new(StandardError)
      ArgumentError = Class.new(BaseError)
      ProjectAlreadyExists = Class.new(BaseError)
      ProjectNotFound = Class.new(BaseError)
      ResourceNotAvailable = Class.new(BaseError)
      ConfigurationError = Class.new(BaseError)
      ConnectionFailed = Class.new(BaseError)
    end
  end
end
