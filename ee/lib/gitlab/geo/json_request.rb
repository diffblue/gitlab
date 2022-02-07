# frozen_string_literal: true

module Gitlab
  module Geo
    class JsonRequest < BaseRequest
      def headers
        super.merge({ 'Content-Type' => 'application/json' })
      end
    end
  end
end
