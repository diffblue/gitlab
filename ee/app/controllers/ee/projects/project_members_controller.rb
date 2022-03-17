# frozen_string_literal: true

module EE
  module Projects
    module ProjectMembersController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        before_action :check_membership_lock!, only: [:import, :apply_import]
      end

      def check_membership_lock!
        access_denied!('Membership is locked by group settings') if membership_locked?
      end

      protected

      override :invited_members
      def invited_members
        super.or(members.awaiting.with_invited_user_state)
      end

      override :non_invited_members
      def non_invited_members
        super.non_awaiting
      end
    end
  end
end
