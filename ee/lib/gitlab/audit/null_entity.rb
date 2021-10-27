# frozen_string_literal: true

module Gitlab
  module Audit
    class NullEntity
      def nil?
        true
      end
    end
  end
end
