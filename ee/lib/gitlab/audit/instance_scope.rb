# frozen_string_literal: true

module Gitlab
  module Audit
    class InstanceScope
      SCOPE_NAME = "gitlab_instance"
      SCOPE_ID = 1

      attr_reader :id, :name, :full_path

      def initialize
        @id = SCOPE_ID
        @name = SCOPE_NAME
        @full_path = SCOPE_NAME
      end

      def licensed_feature_available?(feature)
        ::License.feature_available?(feature)
      end
    end
  end
end
