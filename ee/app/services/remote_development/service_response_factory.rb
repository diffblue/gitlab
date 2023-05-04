# frozen_string_literal: true

module RemoteDevelopment
  module ServiceResponseFactory
    # @param [Hash] response_hash
    # @return [ServiceResponse]
    def create_service_response(response_hash)
      # NOTE: We are not using the ServiceResponse class directly in the Domain Logic layer, but instead we
      # have the Domain Logic layer return a hash with the necessary entries to create a ServiceResponse object.
      # This is because:
      #
      # 1. It makes the specs for the classes on the outer edge of the Domain Logic layer more concise
      #    and straightforward if they can assert on plain hash return values rather than unpacking ServiceResponse
      #    objects.
      # 2. We can use this as a centralized place to do some type-checking of the values to be contained in
      #    the ServiceResponse (this could be added to ServiceResponse in the future if we choose, but it is
      #    currently dependent upon the experimental rightward assignment feature).
      # 3. This would technically be a circular dependency, since the ServiceResponse class is part of the
      #    Service layer, but the Service layer calls the Domain Logic layer.
      #
      # We may change this in the future as we evolve the abstractions around the Service layer,
      # but for now we are keeping them strictly decoupled.
      #
      # See ee/lib/remote_development/README.md for more context.

      validate_response_hash(response_hash)
      ServiceResponse.new(**response_hash)
    end

    private

    # @param [Hash] response_hash
    # @return [void]
    # @raise [RuntimeError]
    def validate_response_hash(response_hash)
      # Explicitly assign nil to all valid values, so we can type-check the values using rightward assignment,
      #    which requires that nil values must be explicitly set.
      hash = { status: nil, payload: nil, message: nil, reason: nil }.merge(response_hash)

      # Type-check response using rightward assignment
      hash => {
        status: Symbol => status,
        payload: (Hash | NilClass) => payload,
        message: (String | NilClass) => message,
        reason: (Symbol | NilClass)=> reason,
      }

      raise "Invalid 'status:' value for response: #{status}" unless [:success, :error].include?(status)

      # NOTE: These rules are more strict than the ones in ServiceResponse, but we want to enforce this pattern of
      #       usage within the Remote Development domain.
      if status == :success
        raise "'reason:' cannot specified if 'status:' is :success" if reason

        raise "'message:' cannot specified if 'status:' is :success" if message

        raise "'payload:' must specified if 'status:' is :success" if payload.nil?
      else
        raise "'reason:' must be specified if 'status:' is :error" if reason.nil?

        raise "'message:' must be specified if 'status:' is :error" if message.nil?

        raise "'payload:' cannot be specified if 'status:' is :error" if payload
      end

      nil
    end
  end
end
