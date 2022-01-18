# frozen_string_literal: true

module Security
  class Training < ApplicationRecord
    self.table_name = 'security_trainings'

    belongs_to :project, optional: false
    belongs_to :provider, optional: false, inverse_of: :trainings, class_name: 'Security::TrainingProvider'

    validates :project_id, uniqueness: true, if: :is_primary?
  end
end
