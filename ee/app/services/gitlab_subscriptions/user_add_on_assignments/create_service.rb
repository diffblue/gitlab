# frozen_string_literal: true

module GitlabSubscriptions
  module UserAddOnAssignments
    class CreateService < BaseService
      ERROR_NO_SEATS_AVAILABLE = 'NO_SEATS_AVAILABLE'
      ERROR_INVALID_USER_MEMBERSHIP = 'INVALID_USER_MEMBERSHIP'

      def initialize(add_on_purchase:, user:)
        @add_on_purchase = add_on_purchase
        @user = user
      end

      def execute
        return ServiceResponse.success if user_already_assigned?

        errors = validate

        if errors.blank?
          # TODO: implement resource locking to avoid race condition
          # https://gitlab.com/gitlab-org/gitlab/-/issues/415584#race-condition
          add_on_purchase.assigned_users.create!(user: user)

          ServiceResponse.success
        else
          ServiceResponse.error(message: errors)
        end
      end

      private

      attr_reader :add_on_purchase, :user

      def validate
        return ERROR_NO_SEATS_AVAILABLE unless seats_available?
        return ERROR_INVALID_USER_MEMBERSHIP unless billed_member_of_namespace?
      end

      def seats_available?
        add_on_purchase.quantity > assigned_seats
      end

      def assigned_seats
        @assigned_seats ||= add_on_purchase.assigned_users.count
      end

      def user_already_assigned?
        add_on_purchase.already_assigned?(user)
      end

      def billed_member_of_namespace?
        namespace.billed_group_user?(user, exclude_guests: true) ||
          namespace.billed_project_user?(user, exclude_guests: true) ||
          namespace.billed_shared_group_user?(user, exclude_guests: true) ||
          namespace.billed_shared_project_user?(user, exclude_guests: true)
      end

      def namespace
        @namespace ||= add_on_purchase.namespace
      end
    end
  end
end
