# frozen_string_literal: true

module Gitlab
  module Email
    class FeatureFlagWrapper
      def initialize(email)
        @email = email
      end

      def flipper_id
        "Email:#{@email}"
      end
    end
  end
end
