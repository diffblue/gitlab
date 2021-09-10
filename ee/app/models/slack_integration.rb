# frozen_string_literal: true

class SlackIntegration < ApplicationRecord
  belongs_to :integration, foreign_key: :service_id

  validates :team_id, presence: true
  validates :team_name, presence: true
  validates :alias, presence: true,
                    uniqueness: { scope: :team_id, message: 'This alias has already been taken' },
                    length: 2..4096
  validates :user_id, presence: true
  validates :integration, presence: true

  after_commit :update_active_status_of_integration, on: [:create, :destroy]

  def update_active_status_of_integration
    integration.update_active_status
  end
end
