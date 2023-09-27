# frozen_string_literal: true

module GitlabSubscriptions
  module UserAddOnAssignments
    class CreateService < BaseService
      include Gitlab::Utils::StrongMemoize

      ERROR_NO_SEATS_AVAILABLE = 'NO_SEATS_AVAILABLE'
      ERROR_INVALID_USER_MEMBERSHIP = 'INVALID_USER_MEMBERSHIP'
      VALIDATION_ERROR_CODE = 422

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

        error = validate

        if error.blank?
          add_on_purchase.with_lock do
            raise NoSeatsAvailableError unless seats_available?

            add_on_purchase.assigned_users.create!(user: user)
          end

          log_event('User AddOn assignment created')

          ServiceResponse.success
        else
          log_event('User AddOn assignment creation failed', error: error, error_code: VALIDATION_ERROR_CODE)

          ServiceResponse.error(message: error)
        end
      rescue NoSeatsAvailableError => error
        Gitlab::ErrorTracking.log_exception(
          error, base_log_params.merge({ message: 'User AddOn assignment creation failed' })
        )

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
        namespace.billed_group_user?(user) ||
          namespace.billed_project_user?(user) ||
          namespace.billed_shared_group_user?(user) ||
          namespace.billed_shared_project_user?(user)
      end
      strong_memoize_attr :billed_member_of_namespace?

      def namespace
        @namespace ||= add_on_purchase.namespace
      end

      def log_event(message, error: nil, error_code: nil)
        log_params = base_log_params.tap do |result|
          result[:message] = message
          result[:error] = error if error
          result[:error_code] = error_code if error_code
        end

        Gitlab::AppLogger.info(log_params)
      end

      def base_log_params
        {
          user: user.username.to_s,
          add_on: add_on_purchase.add_on.name,
          namespace: add_on_purchase.namespace.path
        }
      end
    end
  end
end
