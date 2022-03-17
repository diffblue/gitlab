# frozen_string_literal: true

module Security
  class Training < ApplicationRecord
    self.table_name = 'security_trainings'

    belongs_to :project, optional: false
    belongs_to :provider, optional: false, inverse_of: :trainings, class_name: 'Security::TrainingProvider'

    # There can be only one primary training per project
    validates :is_primary, uniqueness: { scope: :project_id }, if: :is_primary?

    before_destroy :prevent_deleting_primary

    scope :not_including, -> (training) { where.not(id: training.id) }

    private

    # We prevent deleting the primary training
    # if there are other trainings enabled for the project.
    # Users have to select another primary before deleting trainings.
    def prevent_deleting_primary
      return unless is_primary? && other_trainings_available?

      errors.add(:base, _("Can not delete primary training"))

      throw :abort # rubocop:disable Cop/BanCatchThrow
    end

    def other_trainings_available?
      project.security_trainings.not_including(self).exists?
    end
  end
end
