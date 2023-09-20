# frozen_string_literal: true

module EE
  module Resolvers
    module IssuesResolver
      extend ActiveSupport::Concern

      class_methods do
        def project_associations
          super.push(:invited_groups)
        end
      end
    end
  end
end
