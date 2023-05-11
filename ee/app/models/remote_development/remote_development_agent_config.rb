# frozen_string_literal: true

module RemoteDevelopment
  # noinspection RailsParamDefResolve
  class RemoteDevelopmentAgentConfig < ApplicationRecord
    # NOTE: See the following comment for the reasoning behind the `RemoteDevelopment` prefix of this table/model:
    #       https://gitlab.com/gitlab-org/gitlab/-/issues/410045#note_1385602915
    belongs_to :agent,
      class_name: 'Clusters::Agent', foreign_key: 'cluster_agent_id', inverse_of: :remote_development_agent_config

    has_many :workspaces, through: :agent, source: :workspaces

    validates :enabled, presence: true
    validates :agent, presence: true

    # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409772 - Make this a type:enum
    validates :enabled, inclusion: { in: [true], message: 'is currently immutable, and must be set to true' }
    # noinspection RubyResolve
    before_validation :prevent_dns_zone_update, if: ->(record) { record.persisted? && record.dns_zone_changed? }

    private

    def prevent_dns_zone_update
      errors.add(:dns_zone, _('is currently immutable, and cannot be updated. Create a new agent instead.'))
    end
  end
end
