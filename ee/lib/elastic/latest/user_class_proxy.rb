# frozen_string_literal: true

module Elastic
  module Latest
    class UserClassProxy < ApplicationClassProxy
      include StateFilter

      def elastic_search(query, options: {})
        raise NotImplementedError
      end
    end
  end
end
