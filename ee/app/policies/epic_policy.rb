# frozen_string_literal: true

class EpicPolicy < BasePolicy
  include CrudPolicyHelpers

  delegate { @subject.group }

  desc 'Epic is confidential'
  condition(:confidential, scope: :subject) do
    @subject.confidential?
  end

  condition(:related_epics_available, scope: :subject) do
    @subject.group.licensed_feature_available?(:related_epics)
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
    prevent(*create_read_update_admin_destroy(:epic))
    prevent :read_epic_iid
    prevent :create_note
    prevent :award_emoji
    prevent :read_note
  end

  rule { ~anonymous & can?(:read_epic) }.policy do
    enable :create_todo
  end

  rule { can?(:admin_epic) }.policy do
    enable :set_epic_metadata
    enable :set_confidentiality
  end

  rule { can?(:read_epic) & related_epics_available }.policy do
    enable :read_related_epic_link
  end

  rule { can?(:admin_epic) & related_epics_available }.policy do
    enable :admin_related_epic_link
  end

  rule { can?(:reporter_access) }.policy do
    enable :mark_note_as_confidential
  end

  # This rule replicates permissions in NotePolicy#can_read_confidential
  rule { can?(:reporter_access) | admin }.policy do
    enable :read_internal_note
  end
end
