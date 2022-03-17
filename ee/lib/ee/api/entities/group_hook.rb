# frozen_string_literal: true

module EE
  module API
    module Entities
      class GroupHook < ::API::Entities::Hook
        expose :group_id, :issues_events, :confidential_issues_events,
               :note_events, :confidential_note_events, :pipeline_events, :wiki_page_events,
               :job_events, :deployment_events, :releases_events, :subgroup_events
        expose :push_events_branch_filter
      end
    end
  end
end
