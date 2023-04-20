# frozen_string_literal: true

# @params target [MergeRequest, Project]
# @params params [Hash] for updating or creating target
# @params user [User] current user
#
# Returns a copy of `params` with rules modified,
# filtering rule users and groups based on accessibility from user
module ApprovalRules
  class ParamsFilteringService
    include Gitlab::Utils::StrongMemoize

    attr_reader :target, :params, :current_user, :rules, :visible_group_ids, :visible_user_ids

    def initialize(target, user, params)
      @target = target
      @current_user = user
      @params = params.to_h.with_indifferent_access

      batch_load_visible_user_and_group_ids
    end

    def execute
      params.delete(:approval_rules_attributes) unless current_user.can?(:update_approvers, target)
      params.delete(:reset_approval_rules_to_defaults) unless updating?

      return params unless params.key?(:approval_rules_attributes)

      source_rule_ids = []

      params[:approval_rules_attributes].each do |rule_attributes|
        source_rule_ids << rule_attributes[:approval_project_rule_id].presence
        handle_rule(rule_attributes)
      end

      append_user_defined_inapplicable_rules(source_rule_ids.compact)

      params
    end

    private

    def handle_rule(rule_attributes)
      if rule_attributes.key?(:group_ids)
        provided_group_ids = rule_attributes[:group_ids].map(&:to_i)
        rule_attributes[:group_ids] = provided_group_ids & visible_group_ids

        append_hidden_groups(rule_attributes)
      end

      if rule_attributes.key?(:user_ids)
        provided_user_ids = rule_attributes[:user_ids].map(&:to_i)
        rule_attributes[:user_ids] = provided_user_ids & visible_user_ids
      end

      if rule_attributes[:group_ids].blank? && rule_attributes[:user_ids].blank? && rule_attributes[:name].blank?
        rule_attributes[:rule_type] = :any_approver
        rule_attributes[:name] = ApprovalRuleLike::ALL_MEMBERS
      end
    end

    # Append hidden groups to params to prevent them from being removed,
    # as hidden group ids are never passed to/back from clients for security reasons.
    def append_hidden_groups(rule_attributes)
      keep_hidden_groups = !Gitlab::Utils.to_boolean(rule_attributes.delete(:remove_hidden_groups))

      return unless keep_hidden_groups
      return unless rule_attributes.key?(:group_ids)

      hidden_group_sourcing_rule = find_hidden_group_sourcing_rule(rule_attributes)

      return unless hidden_group_sourcing_rule

      rule_attributes[:group_ids].concat(
        ::ApprovalRules::GroupFinder.new(hidden_group_sourcing_rule, current_user).hidden_groups.map(&:id)
      )
    end

    # Allow ruby-level filtering with only 2 queries
    def batch_load_visible_user_and_group_ids
      return unless params.key?(:approval_rules_attributes)

      # rubocop: disable CodeReuse/ActiveRecord
      @visible_group_ids = params[:approval_rules_attributes].flat_map { |hash| hash[:group_ids] }

      if @visible_group_ids.present?
        @visible_group_ids = ::Group.id_in(@visible_group_ids).accessible_to_user(current_user).pluck(:id)
      end

      @visible_user_ids = params[:approval_rules_attributes].flat_map { |hash| hash[:user_ids] }
      if @visible_user_ids.present?
        @visible_user_ids = project.members_among(::User.id_in(@visible_user_ids)).pluck(:id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    def project
      if target.is_a?(Project)
        target
      else
        target.target_project
      end
    end

    def updating?
      strong_memoize(:updating) { @target.persisted? }
    end

    def find_hidden_group_sourcing_rule(rule_attributes)
      rule_id = updating? ? rule_attributes[:id] : rule_attributes[:approval_project_rule_id]

      return if rule_id.blank?

      hidden_group_sourcing_rules[rule_id.to_i]
    end

    def hidden_group_sourcing_rules
      strong_memoize(:hidden_group_sourcing_rules) do
        source = updating? ? target : project
        source.approval_rules.includes(:groups).index_by(&:id) # rubocop: disable CodeReuse/ActiveRecord
      end
    end

    # Append inapplicable rules on create or reset so they're still associated
    # to the MR and will be available when the MR's target branch changes.
    #
    # Inapplicable rules are approval rules scoped to protected branches that
    # does not match the specified `target_branch`.
    #
    # For example, there are 2 rules, one scoped to `master`, one scoped to `dev`.
    # The MR's `target_branch` is set to `dev`, so the rule for `master` is
    # inapplicable. But in case the MR's `target_branch` changes to `master`, the
    # `master` rule should be available.
    def append_user_defined_inapplicable_rules(source_rule_ids)
      return if updating? && !params[:reset_approval_rules_to_defaults]
      return unless project.multiple_approval_rules_available?

      project
        .visible_user_defined_inapplicable_rules(params[:target_branch])
        .each do |rule|
          # Check if rule is already set as a source rule in one of the rules
          # from params to prevent duplicates
          next if source_rule_ids.include?(rule.id)

          params[:approval_rules_attributes] << rule.to_nested_attributes
        end
    end
  end
end
