# frozen_string_literal: true

# For caching group related queries relative to current_user
module ApprovalRules
  class GroupFinder
    include Gitlab::Utils::StrongMemoize

    attr_reader :rule, :current_user

    def initialize(rule, user)
      @rule = rule
      @current_user = user
    end

    def visible_groups
      if Feature.enabled?(:subgroups_approval_rules, rule.project)
        strong_memoize(:visible_groups) do
          Preloaders::GroupPolicyPreloader.new(groups, current_user).execute
          groups.select { |group| current_user.can?(:read_group, group) }
        end
      else
        @visible_groups ||= groups.public_or_visible_to_user(current_user)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def hidden_groups
      @hidden_groups ||= groups.where.not(id: visible_groups.map(&:id))
    end

    def contains_hidden_groups?
      hidden_groups.loaded? ? hidden_groups.present? : hidden_groups.exists?
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def groups
      strong_memoize(:groups) do
        rule.any_approver? ? Group.none : rule.groups
      end
    end
  end
end
