# frozen_string_literal: true
module EE
  module Groups
    module AutocompleteService
      # rubocop: disable CodeReuse/ActiveRecord
      def epics(confidential_only: false)
        finder_params = { group_id: group.id }
        finder_params[:confidential] = true if confidential_only.present?

        # TODO: use include_descendant_groups: true optional parameter once frontend supports epics from external groups.
        # See https://gitlab.com/gitlab-org/gitlab/issues/6837
        EpicsFinder.new(current_user, finder_params)
          .execute
          .preload(:group)
          .select(:iid, :title, :group_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def iterations
        finder_params = { parent: group, include_ancestors: true, state: 'opened' }

        IterationsFinder.new(current_user, finder_params).execute
      end

      def vulnerabilities
        ::Autocomplete::VulnerabilitiesAutocompleteFinder
          .new(current_user, group, params)
          .execute
          .select([:id, :title, :project_id])
      end
    end
  end
end
