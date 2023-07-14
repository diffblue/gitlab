# frozen_string_literal: true

module Namespaces
  class BilledUsersFinder
    def initialize(group, exclude_guests: false)
      @group = group
      @ids = { user_ids: Set.new }
      @exclude_guests = exclude_guests
    end

    def execute
      METHOD_KEY_MAP.each_key do |method_name|
        calculate_user_ids(method_name)
      end

      ids
    end

    private

    attr_reader :group, :ids

    METHOD_KEY_MAP = {
      billed_group_users: :group_member_user_ids,
      billed_project_users: :project_member_user_ids,
      billed_shared_group_users: :shared_group_user_ids,
      billed_invited_group_to_project_users: :shared_project_user_ids
    }.freeze

    def calculate_user_ids(method_name)
      cross_join_issue = "https://gitlab.com/gitlab-org/gitlab/-/issues/417464"
      ::Gitlab::Database.allow_cross_joins_across_databases(url: cross_join_issue) do
        @ids[METHOD_KEY_MAP[method_name]] = group.public_send(method_name, exclude_guests: @exclude_guests) # rubocop:disable GitlabSecurity/PublicSend
                                            .pluck(:id).to_set # rubocop:disable CodeReuse/ActiveRecord

        append_to_user_ids(ids[METHOD_KEY_MAP[method_name]])
      end
    end

    def append_to_user_ids(user_ids)
      @ids[:user_ids] += user_ids
    end
  end
end
