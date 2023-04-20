# frozen_string_literal: true

module EE
  module API
    module Namespaces
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          params :optional_list_params_ee do
            # Used only by GitLab.com
            optional :requested_hosted_plan, type: String, desc: "Name of the hosted plan requested by the customer"
          end

          override :custom_namespace_present_options
          def custom_namespace_present_options
            { requested_hosted_plan: params[:requested_hosted_plan] }
          end

          def update_namespace(namespace)
            update_attrs = declared_params(include_missing: false)

            # Reset last_ci_minutes_notification_at if customer purchased extra CI minutes.
            if params[:extra_shared_runners_minutes_limit].present?
              update_attrs[:last_ci_minutes_notification_at] = nil
              update_attrs[:last_ci_minutes_usage_notification_level] = nil

              ::Ci::Runner.instance_type.each(&:tick_runner_queue)
            end

            namespace.update(update_attrs).tap do
              if update_attrs[:extra_shared_runners_minutes_limit].present? || update_attrs.key?(:shared_runners_minutes_limit)
                ::Ci::Minutes::RefreshCachedDataService.new(namespace).execute
                ::Ci::Minutes::NamespaceMonthlyUsage.reset_current_notification_level(namespace)
              end
            end
          end
        end

        resource :namespaces, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          helpers do
            params :gitlab_subscription_optional_attributes do
              optional :start_date, type: Date, desc: 'Start date of subscription'
              optional :seats, type: Integer, desc: 'Number of seats in subscription'
              optional :max_seats_used, type: Integer, desc: 'Highest number of active users in the last month'
              optional :plan_code, type: String, desc: 'Subscription tier code'
              optional :end_date, type: Date, desc: 'End date of subscription'
              optional :auto_renew, type: Grape::API::Boolean, desc: 'Whether subscription will auto renew on end date'
              optional :trial, type: Grape::API::Boolean, desc: 'Whether the subscription is a trial'
              optional :trial_ends_on, type: Date, desc: 'End date of trial'
              optional :trial_starts_on, type: Date, desc: 'Start date of trial'
              optional :trial_extension_type, type: Integer, desc: 'Whether subscription is an extended or reactivated trial'
            end
          end

          desc 'Update a namespace' do
            success ::API::Entities::Namespace
          end
          params do
            optional :shared_runners_minutes_limit, type: Integer, desc: "Pipeline minutes quota for this namespace"
            optional :extra_shared_runners_minutes_limit, type: Integer, desc: "Extra pipeline minutes for this namespace"
            optional :additional_purchased_storage_size, type: Integer, desc: "Additional storage size for this namespace"
            optional :additional_purchased_storage_ends_on, type: Date, desc: "End of subscription of the additional purchased storage"
            optional :gitlab_subscription_attributes, type: Hash do
              use :gitlab_subscription_optional_attributes
            end
          end
          put ':id', feature_category: :subgroups, urgency: :low do
            authenticated_as_admin!

            namespace = find_namespace(params[:id])

            break not_found!('Namespace') unless namespace

            if update_namespace(namespace)
              present namespace, with: ::API::Entities::Namespace, current_user: current_user
            else
              render_validation_error!(namespace)
            end
          end

          desc 'Create a subscription for the namespace' do
            success ::API::Entities::GitlabSubscription
          end
          params do
            use :gitlab_subscription_optional_attributes

            requires :start_date, type: Date, desc: 'The date when subscription was started'
          end
          post ":id/gitlab_subscription", urgency: :low, feature_category: :purchase do
            authenticated_as_admin!

            namespace = find_namespace!(params[:id])

            subscription_params = declared_params(include_missing: false)
            subscription_params[:trial_starts_on] ||= subscription_params[:start_date] if subscription_params[:trial]
            subscription = namespace.create_gitlab_subscription(subscription_params)
            if subscription.persisted?
              present subscription, with: ::API::Entities::GitlabSubscription
            else
              render_validation_error!(subscription)
            end
          end

          desc 'Returns the subscription for the namespace' do
            success ::API::Entities::GitlabSubscription
          end
          get ":id/gitlab_subscription", urgency: :low, feature_category: :purchase do
            namespace = find_namespace!(params[:id])
            if ::Feature.enabled?(:auditor_billing_page_access, namespace)
              authorize! :read_billing, namespace
            else
              authorize! :admin_namespace, namespace
            end

            present namespace.gitlab_subscription || {}, with: ::API::Entities::GitlabSubscription
          end

          desc 'Update the subscription for the namespace' do
            success ::API::Entities::GitlabSubscription
          end
          params do
            use :gitlab_subscription_optional_attributes
          end
          put ":id/gitlab_subscription", urgency: :low, feature_category: :purchase do
            authenticated_as_admin!

            namespace = find_namespace!(params[:id])
            subscription = namespace.gitlab_subscription

            not_found!('GitlabSubscription') unless subscription

            subscription_params = declared_params(include_missing: false)
            subscription_params[:trial_starts_on] ||= subscription_params[:start_date] if subscription_params[:trial]
            subscription_params[:updated_at] = Time.current

            if subscription.update(subscription_params)
              present subscription, with: ::API::Entities::GitlabSubscription
            else
              render_validation_error!(subscription)
            end
          end

          desc 'Creates a storage limit exclusion for a Namespace' do
            detail 'Creates a Namespaces::Storage::LimitExclusion'
            success code: 201, model: ::API::Entities::Namespaces::Storage::LimitExclusion
            failure [
              { code: 400, message: 'Bad request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not found' }
            ]
          end
          params do
            requires :reason, type: String, desc: 'The reason the Namespace is being excluded'
          end
          post ':id/storage/limit_exclusion', feature_category: :consumables_cost_management do
            authenticated_as_admin!
            forbidden!('this API is for GitLab.com only') unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

            namespace = find_namespace!(params[:id])

            bad_request!('must use a root namespace') unless namespace.root?
            bad_request!('already excluded') if namespace.storage_limit_exclusion

            limit_exclusion = namespace.build_storage_limit_exclusion(
              reason: params[:reason]
            )

            if limit_exclusion.save
              present limit_exclusion, with: ::API::Entities::Namespaces::Storage::LimitExclusion
            else
              render_validation_error!(limit_exclusion)
            end
          end

          desc 'Removes a storage limit exclusion for a Namespace' do
            detail 'Removes a Namespaces::Storage::LimitExclusion'
            success code: 204
            failure [
              { code: 400, message: 'Bad request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 422, message: 'Unprocessable entity' }
            ]
          end
          delete ':id/storage/limit_exclusion' do
            authenticated_as_admin!
            forbidden!('this API is for GitLab.com only') unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

            namespace = find_namespace!(params[:id])

            bad_request!('must use a root namespace') unless namespace.root?
            bad_request!('not excluded') unless namespace.storage_limit_exclusion

            if namespace.storage_limit_exclusion.destroy
              no_content!
            else
              unprocessable_entity!('Exclusion could not be removed')
            end
          end

          desc 'Retrieve all limit exclusions' do
            detail 'Gets all records for namespaces that have been excluded'
            success code: 200, model: ::API::Entities::Namespaces::Storage::LimitExclusion
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' }
            ]
          end
          params do
            use :pagination
          end
          get 'storage/limit_exclusions', feature_category: :consumables_cost_management do
            authenticated_as_admin!
            forbidden!('this API is for GitLab.com only') unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

            exclusions = ::Namespaces::Storage::LimitExclusion.all

            present paginate(exclusions), with: ::API::Entities::Namespaces::Storage::LimitExclusion
          end
        end
      end
    end
  end
end
