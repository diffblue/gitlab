# frozen_string_literal: true

# A view object to ONLY handle approver list display.
# Keeps internal states for performance purpose.
#
# Initialize with following params:
# - skip_user
class MergeRequestApproverPresenter < Gitlab::View::Presenter::Simple
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::RecordIdentifier
  include Gitlab::Utils::StrongMemoize

  presents ::MergeRequest, as: :merge_request

  attr_reader :skip_user

  def initialize(merge_request, **attributes)
    @skip_user = merge_request.author || attributes.delete(:skip_user)
    super
  end

  def any?
    users.any?
  end

  def render
    safe_join(users.map { |user| render_user(user) }, ', ')
  end

  def render_user(user)
    ApplicationController.helpers.link_to user.name, '#', id: dom_id(user)
  end

  def show_code_owner_tips?
    code_owner_enabled? && code_owner_loader.empty_code_owners?
  end

  private

  def users
    strong_memoize(:users) do
      merge_request.project.members_among(users_from_git_log_authors)
    end
  end

  def code_owner_enabled?
    strong_memoize(:code_owner_enabled) do
      merge_request.project.feature_available?(:code_owners)
    end
  end

  def users_from_git_log_authors
    if merge_request.approvals_required > 0
      ::Gitlab::AuthorityAnalyzer.new(merge_request, skip_user).calculate.first(merge_request.approvals_required)
    else
      []
    end
  end

  def code_owner_loader
    @code_owner_loader ||= Gitlab::CodeOwners::Loader.new(
      merge_request.target_project,
      merge_request.target_branch,
      merge_request.modified_paths
    )
  end
end
