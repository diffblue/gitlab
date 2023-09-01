# frozen_string_literal: true

module EE
  module PagesDomain
    extend ActiveSupport::Concern

    prepended do
      scope :with_logging_info, -> { includes(project: [:route, { namespace: :gitlab_subscription }]) }
    end

    def root_group
      return unless project
      return unless project.root_namespace.group_namespace?

      project.root_namespace
    end
  end
end
