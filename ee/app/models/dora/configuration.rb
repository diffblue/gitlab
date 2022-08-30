# frozen_string_literal: true

module Dora
  class Configuration < ApplicationRecord
    self.table_name = 'dora_configurations'

    belongs_to :project

    validates :project_id, uniqueness: true, presence: true
    validates :branches_for_lead_time_for_changes, length: { minimum: 0, allow_nil: false, message: :blank }
  end
end
