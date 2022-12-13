# frozen_string_literal: true

class SlackIntegration < ApplicationRecord
  include EachBatch

  belongs_to :integration

  attr_encrypted :bot_access_token,
    mode: :per_attribute_iv,
    key: Settings.attr_encrypted_db_key_base_32,
    algorithm: 'aes-256-gcm',
    encode: false,
    encode_iv: false

  has_many :slack_integrations_scopes,
    class_name: '::Integrations::SlackIntegrationsKnownApiScope'

  has_many :slack_api_scopes,
    class_name: '::Integrations::KnownSlackApiScope',
    through: :slack_integrations_scopes

  scope :with_bot, -> { where.not(bot_user_id: nil) }
  scope :by_team, -> (team_id) { where(team_id: team_id) }
  scope :legacy_by_team, -> (team_id) { by_team(team_id).where(bot_user_id: nil) }

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

  def feature_available?(feature_name)
    case feature_name
    when :commands
      scoped_to?('commands')
    when :notifications
      scoped_to?('chat:write', 'chat:write.public')
    else
      false
    end
  end

  def authorized_scope_names=(names)
    scopes = ::Integrations::KnownSlackApiScope.find_or_initialize_by_names(names)
    self.slack_api_scopes = scopes
  end

  def authorized_scope_names
    slack_api_scopes.pluck(:name)
  end

  private

  def scoped_to?(*names)
    return false if names.empty?

    names.to_set <= all_scopes
  end

  def all_scopes
    @all_scopes = authorized_scope_names.to_set
  end
end
