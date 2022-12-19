# frozen_string_literal: true

class EpicIssue < ApplicationRecord
  include EpicTreeSorting
  include EachBatch
  include AfterCommitQueue

  validates :epic, :issue, presence: true
  validates :issue, uniqueness: true

  belongs_to :epic
  belongs_to :issue

  alias_attribute :parent_ids, :epic_id
  alias_attribute :parent, :epic

  scope :in_epic, ->(epic_id) { where(epic_id: epic_id) }

  validate :validate_confidential_epic
  after_commit :update_cached_metadata

  def epic_tree_root?
    false
  end

  def self.epic_tree_node_query(node)
    selection = <<~SELECT_LIST
      id, relative_position, epic_id as parent_id, epic_id, '#{underscore}' as object_type
    SELECT_LIST

    select(selection).in_epic(node.parent_ids)
  end

  def exportable_record?(user)
    Ability.allowed?(user, :read_epic, epic)
  end

  private

  def validate_confidential_epic
    return unless epic && issue

    if epic.confidential? && !issue.confidential?
      errors.add :issue, _('Cannot assign a confidential epic to a non-confidential issue. Make the issue confidential and try again')
    end
  end

  def update_cached_metadata
    ::Epics::UpdateCachedMetadataWorker.perform_async([epic_id])

    if epic_id_previously_changed? && epic_id_previously_was
      ::Epics::UpdateCachedMetadataWorker.perform_async([epic_id_previously_was])
    end
  end
end
