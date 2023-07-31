# frozen_string_literal: true

module GitlabSubscriptions
  module UserAddOnAssignments
    class CreateService < BaseService
      include Gitlab::Utils::StrongMemoize

      ERROR_NO_SEATS_AVAILABLE = 'NO_SEATS_AVAILABLE'
      ERROR_INVALID_USER_MEMBERSHIP = 'INVALID_USER_MEMBERSHIP'

      NoSeatsAvailableError = Class.new(StandardError) do
        def initialize(message = ERROR_NO_SEATS_AVAILABLE)
          super(message)
        end
      end

      def initialize(add_on_purchase:, user:)
        @add_on_purchase = add_on_purchase
        @user = user
      end

      def execute
        return ServiceResponse.success if user_already_assigned?

        errors = validate

        if errors.blank?
          add_on_purchase.with_lock do
            raise NoSeatsAvailableError unless seats_available?

            add_on_purchase.assigned_users.create!(user: user)
          end

          ServiceResponse.success
        else
          ServiceResponse.error(message: errors)
        end
      rescue NoSeatsAvailableError => error
        ServiceResponse.error(message: error.message)
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
        add_on_purchase.assigned_users.count
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
      strong_memoize_attr :billed_member_of_namespace?

      def namespace
        @namespace ||= add_on_purchase.namespace
      end
    end
  end
end
