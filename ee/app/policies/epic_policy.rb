# frozen_string_literal: true

class EpicPolicy < BasePolicy
  include CrudPolicyHelpers

  delegate { @subject.group }

  condition(:service_desk_enabled) do
    @subject.group.has_project_with_service_desk_enabled?
  end

  desc 'Epic is confidential'
  condition(:confidential, scope: :subject) do
    @subject.confidential?
  end

  condition(:related_epics_available, scope: :subject) do
    @subject.group.licensed_feature_available?(:related_epics)
  end

  condition(:subepics_available, scope: :subject) do
    @subject.group.licensed_feature_available?(:subepics)
  end

  condition(:is_member) do
    @subject.group.member?(@user)
  end

  condition(:ai_available, scope: :subject) do
    ::Feature.enabled?(:openai_experimentation) &&
      @subject.group.root_ancestor.experiment_features_enabled &&
      @subject.send_to_ai?
  end

  condition(:summarize_notes_enabled, scope: :subject) do
    ::Feature.enabled?(:summarize_comments, @subject.group) &&
      @subject.group.licensed_feature_available?(:summarize_notes)
  end

  rule { can?(:read_epic) }.policy do
    enable :read_epic_iid
    enable :read_note
    enable :read_issuable_participables
  end

  rule { can?(:read_epic) & ~anonymous }.policy do
    enable :create_note
  end

  rule { can?(:create_note) }.enable :award_emoji

  rule { can?(:owner_access) | can?(:maintainer_access) }.enable :admin_note

  desc 'User cannot read confidential epics'
  rule { confidential & ~can?(:reporter_access) }.policy do
    prevent :create_epic
    prevent :update_epic
    prevent :admin_epic
    prevent :destroy_epic
    prevent :create_note
    prevent :award_emoji
    prevent :read_note
  end

  # Checking for guest access is important as in public groups non-members can read epics,
  # but should not be able to alter epic tree or related epics relationship. User has to
  # have at least a Guest role for that.
  rule { can?(:guest_access) & can?(:read_epic) }.policy do
    # This generic permission means that a user is able to create, read, destroy an epic
    # relationship, but it needs some extra checks depending on the feature:
    # 1. To add an issue to the epic tree this permission is enough
    # 2. To add a sub-epic or link a parent epic we also need to check that sub-epics feature
    # feature is available, i.e. `subepics_available`
    # 3. To add a related epic we also need to check that related epics feature is available,
    # i.e. `related_epics_available`
    enable :admin_epic_relation
  end

  # Used to check permissions of subepics (child-parent relation)
  rule { can?(:admin_epic_relation) & subepics_available }.policy do
    enable :admin_epic_tree_relation
  end

  # Used to check permissions of related epic links (related/blocked/blocking relation)
  rule { can?(:admin_epic_relation) & related_epics_available }.policy do
    enable :admin_epic_link_relation
  end

  # Special case to not prevent support bot
  # assigning issues to confidential epics using quick actions
  # when group has projects with service desk enabled.
  rule { confidential & ~can?(:reporter_access) & ~(support_bot & service_desk_enabled) }.policy do
    prevent :read_epic
    prevent :read_epic_iid
  end

  rule { ~anonymous & can?(:read_epic) }.policy do
    enable :create_todo
  end

  rule { can?(:admin_epic) }.policy do
    enable :set_epic_metadata
    enable :set_confidentiality
  end

  rule { can?(:reporter_access) }.policy do
    enable :mark_note_as_internal
  end

  rule { ai_available & summarize_notes_enabled & is_member & ~confidential }.policy do
    enable :summarize_notes
  end
end
