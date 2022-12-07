# frozen_string_literal: true

module EE
  module Members
    module CreatorService
      extend ::Gitlab::Utils::Override

      private

      override :member_attributes
      def member_attributes
        super.merge(ldap: ldap)
      end
    end
  end
end
