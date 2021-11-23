# frozen_string_literal: true

module EE
  module API
    module Entities
      module Member
        extend ActiveSupport::Concern

        prepended do
          expose :group_saml_identity,
                 using: ::API::Entities::Identity,
                 if: -> (member, options) { Ability.allowed?(options[:current_user], :read_group_saml_identity, member.source) }

          expose :is_using_seat, if: -> (_, options) { options[:show_seat_info] }

          expose :override,
                 if: ->(member, _) { member.source_type == 'Namespace' && member.ldap? }

          expose :human_state_name, as: :membership_state
        end
      end
    end
  end
end
