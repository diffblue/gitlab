# frozen_string_literal: true

module EE
  module DescriptionVersion
    extend ActiveSupport::Concern

    prepended do
      belongs_to :epic

      # This scope is using `deleted_at` column which is not indexed.
      # Prevent using it in not scoped contexts.
      scope :visible, -> { where(deleted_at: nil) }
    end

    class_methods do
      def issuable_attrs
        (super + %i[epic]).freeze
      end
    end

    def issuable
      epic || super
    end

    def previous_version
      issuable_description_versions
        .where('created_at < ?', created_at)
        .order(created_at: :desc, id: :desc)
        .first
    end

    # Soft deletes a description version.
    # If start_id is given it soft deletes current version
    # up to start_id of the same issuable.
    def delete!(start_id: nil)
      start_id ||= self.id

      description_versions =
        issuable_description_versions.where('id BETWEEN ? AND ?', start_id, self.id)

      description_versions.update_all(deleted_at: Time.current)

      issuable&.broadcast_notes_changed
    end

    def deleted?
      self.deleted_at.present?
    end

    private

    def issuable_description_versions
      self.class.where(
        issue_id: issue_id,
        merge_request_id: merge_request_id,
        epic_id: epic_id
      )
    end
  end
end
