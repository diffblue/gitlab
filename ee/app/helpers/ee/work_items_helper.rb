# frozen_string_literal: true

module EE
  module WorkItemsHelper
    extend ::Gitlab::Utils::Override

    override :work_items_index_data
    def work_items_index_data(project)
      super.merge(
        has_issue_weights_feature: project.licensed_feature_available?(:issue_weights).to_s,
        has_okrs_feature: project.licensed_feature_available?(:okrs).to_s,
        has_iterations_feature: project.licensed_feature_available?(:iterations).to_s,
        has_issuable_health_status_feature: project.licensed_feature_available?(:issuable_health_status).to_s
      )
    end
  end
end
