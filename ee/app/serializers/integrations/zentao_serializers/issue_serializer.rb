# frozen_string_literal: true

module Integrations
  module ZentaoSerializers
    class IssueSerializer < BaseSerializer
      include WithPagination

      entity ::Integrations::ZentaoSerializers::IssueEntity
    end
  end
end
