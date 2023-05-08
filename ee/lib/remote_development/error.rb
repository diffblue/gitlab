# frozen_string_literal: true

module RemoteDevelopment
  class Error
    attr_accessor :message, :reason

    def initialize(message:, reason:)
      @message = message
      @reason = reason
    end
  end
end
