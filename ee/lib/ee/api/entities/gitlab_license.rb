# frozen_string_literal: true

module EE
  module API
    module Entities
      class GitlabLicense < Grape::Entity
        expose :id, documentation: { type: 'string', example: 1 }
        expose :plan, documentation: { type: 'string', example: 'silver' }
        expose :created_at, documentation: { type: 'dateTime', example: '2012-05-28T04:42:42-07:00' }
        expose :starts_at, documentation: { type: 'date', example: '2018-01-27' }
        expose :expires_at, documentation: { type: 'date', example: '2022-01-27' }
        expose :historical_max, documentation: { type: 'integer', example: 300 }
        expose :maximum_user_count, documentation: { type: 'integer', example: 300 }
        expose :licensee, documentation: { type: 'Hash', example: { 'Name' => 'John Doe1' } }
        expose :add_ons, documentation: { type: 'Hash',
                                          example: { 'GitLab_FileLocks' => 1, 'GitLab_Auditor_User' => 1 } }

        expose :expired?, as: :expired, documentation: { type: 'boolean' }

        expose :overage, documentation: { type: 'integer', example: 200 } do |license, options|
          license.expired? ? license.overage_with_historical_max : license.overage(options[:current_active_users_count])
        end

        expose :user_limit, documentation: { type: 'integer', example: 200 } do |license, options|
          license.restricted?(:active_user_count) ? license.restrictions[:active_user_count] : 0
        end
      end
    end
  end
end
