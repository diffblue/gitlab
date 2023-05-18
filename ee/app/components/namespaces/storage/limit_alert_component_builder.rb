# frozen_string_literal: true

module Namespaces
  module Storage
    class LimitAlertComponentBuilder
      def self.build(context:, user:)
        if Enforcement.enforce_limit?(context.root_ancestor)
          LimitAlertComponent.new(context: context, user: user)
        else
          RepositoryLimitAlertComponent.new(context: context, user: user)
        end
      end
    end
  end
end
