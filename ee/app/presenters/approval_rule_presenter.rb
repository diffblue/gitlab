# frozen_string_literal: true

class ApprovalRulePresenter < Gitlab::View::Presenter::Delegated
  include Gitlab::Utils::StrongMemoize

  presents nil, as: :rule

  # Hide all approvers if any of them might come from a hidden group. This
  # represents an abundance of caution, but we can't tell which approvers come
  # from a hidden group and which don't, from here, so this is the simplest
  # thing we can do
  def approvers
    return [] if contains_hidden_groups?

    super
  end

  def groups
    group_query_service.visible_groups
  end

  def contains_hidden_groups?
    strong_memoize(:contains_hidden_groups) do
      group_query_service.contains_hidden_groups?
    end
  end

  private

  def group_query_service
    @group_query_service ||= ApprovalRules::GroupFinder.new(rule, current_user)
  end
end
