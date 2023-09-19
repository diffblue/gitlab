# frozen_string_literal: true

module EE
  module API
    module Entities
      module ProjectIntegrationBasic
        extend ActiveSupport::Concern

        prepended do
          expose :vulnerability_events, documentation: { type: 'boolean' }
        end
      end
    end
  end
end
