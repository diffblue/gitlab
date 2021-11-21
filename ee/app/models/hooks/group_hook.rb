# frozen_string_literal: true

class GroupHook < WebHook
  include CustomModelNaming
  include TriggerableHooks
  include Limitable
  extend ::Gitlab::Utils::Override

  self.limit_name = 'group_hooks'
  self.limit_scope = :group
  self.singular_route_key = :hook

  triggerable_hooks [
    :push_hooks,
    :tag_push_hooks,
    :issue_hooks,
    :confidential_issue_hooks,
    :note_hooks,
    :merge_request_hooks,
    :job_hooks,
    :pipeline_hooks,
    :wiki_page_hooks,
    :deployment_hooks,
    :release_hooks,
    :member_hooks,
    :subgroup_hooks
  ]

  belongs_to :group

  validates :url, presence: true, addressable_url: true

  def pluralized_name
    _('Group Hooks')
  end

  override :application_context
  def application_context
    super.merge(namespace: group)
  end

  override :rate_limit
  def rate_limit
    group.actual_limits.limit_for(:web_hook_calls)
  end

  override :parent
  def parent
    group
  end

  private

  override :web_hooks_disable_failed?
  def web_hooks_disable_failed?
    Feature.enabled?(:web_hooks_disable_failed, group)
  end
end
