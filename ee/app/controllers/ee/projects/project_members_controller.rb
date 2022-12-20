# frozen_string_literal: true

module EE
  module Projects
    module ProjectMembersController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      prepended do
        before_action do
          push_frontend_feature_flag(:show_overage_on_role_promotion)
        end
      end

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
