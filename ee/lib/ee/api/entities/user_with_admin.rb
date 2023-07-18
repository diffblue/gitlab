# frozen_string_literal: true

module EE
  module API
    module Entities
      module UserWithAdmin
        extend ActiveSupport::Concern

        prepended do
          expose :using_license_seat?, as: :using_license_seat
          expose :auditor, as: :is_auditor, if: ->(_instance, _opts) { ::License.feature_available?(:auditor_user) }
          expose :provisioned_by_group_id, if: ->(_instance, _opts) { ::License.feature_available?(:group_saml) }

          expose :enterprise_group_id, if: ->(_instance, _opts) {
                                             ::License.feature_available?(:domain_verification)
                                           } do |user|
            user.user_detail&.enterprise_group_id
          end

          expose :enterprise_group_associated_at, if: ->(_instance, _opts) {
                                                        ::License.feature_available?(:domain_verification)
                                                      } do |user|
            user.user_detail&.enterprise_group_associated_at
          end
        end
      end
    end
  end
end
