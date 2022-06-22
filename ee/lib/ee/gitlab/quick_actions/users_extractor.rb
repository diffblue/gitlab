# frozen_string_literal: true

module EE
  module Gitlab
    module QuickActions
      module UsersExtractor
        def find_referenced_users
          super.to_a + users_by_reference
        end

        def usernames
          return super unless expand_groups?

          references.reject { _1.start_with?('@') }
        end

        def expand_groups?
          target.allows_multiple_assignees?
        end

        def found_names(users)
          return super(users) unless expand_groups?

          groups = ::Group.where_full_path_in(references.map { _1.delete_prefix('@') })

          super(users) + groups.map { _1.full_path.downcase }
        end

        def users_by_reference
          return [] unless expand_groups?

          reference_extractor = ::Gitlab::ReferenceExtractor.new(project, current_user)
          reference_extractor.analyze(text, author: current_user, group: group)

          reference_extractor.references(:user) # rubocop: disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
