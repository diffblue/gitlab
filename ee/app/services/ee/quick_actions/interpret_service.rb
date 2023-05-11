# frozen_string_literal: true

module EE
  module QuickActions
    module InterpretService
      extend ActiveSupport::Concern
      # We use "prepended" here instead of including Gitlab::QuickActions::Dsl,
      # as doing so would clear any existing command definitions.
      prepended do
        # rubocop: disable Cop/InjectEnterpriseEditionModule
        include EE::Gitlab::QuickActions::EpicActions
        include EE::Gitlab::QuickActions::IssueActions
        include EE::Gitlab::QuickActions::IssueAndMergeRequestActions
        include EE::Gitlab::QuickActions::MergeRequestActions
        include EE::Gitlab::QuickActions::RelateActions
        # rubocop: enable Cop/InjectEnterpriseEditionModule
      end
    end
  end
end
