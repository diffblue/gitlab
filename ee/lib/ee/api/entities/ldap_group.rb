# frozen_string_literal: true

module EE
  module API
    module Entities
      class LdapGroup < Grape::Entity
        expose :cn, documentation: { type: 'string', example: 'ldap-group-1' }
      end
    end
  end
end
