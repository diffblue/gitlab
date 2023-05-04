# frozen_string_literal: true

module GitlabSubscriptions
  module Trials
    class CreateService
      include ::Gitlab::Utils::StrongMemoize

      def initialize(step:, lead_params:, trial_params:, user:)
        @step = step
        @lead_params = lead_params
        @trial_params = trial_params
        @user = user
      end

      def execute
        case step
        when 'lead'
          lead_flow
        else
          # some bogus request with unknown step or no step
          not_found
        end
      end

      private

      attr_reader :user, :lead_params, :trial_params, :step

      def namespace
        groups_eligible_for_trial = user.manageable_groups_eligible_for_trial
        groups_eligible_for_trial.count == 1 ? groups_eligible_for_trial.first : nil
      end
      strong_memoize_attr :namespace

      def lead_flow
        result = GitlabSubscriptions::CreateLeadService.new.execute({ trial_user: trial_user_params })

        if result.success?
          if namespace.present? # only one trial eligible namespace exists
            apply_trial_flow
          else
            # trigger new creation for next step...
            ServiceResponse.error(message: 'Lead created, but namespace not present', reason: :no_namespace)
          end
        else
          ServiceResponse.error(message: result.message, reason: :lead_failed)
        end
      end

      def trial_user_params
        attrs = {
          work_email: user.email,
          uid: user.id,
          setup_for_company: user.setup_for_company,
          skip_email_confirmation: true,
          gitlab_com_trial: true,
          provider: 'gitlab',
          newsletter_segment: user.email_opted_in
        }

        lead_params.merge(attrs)
      end

      def apply_trial_flow
        trial_params[:namespace_id] = namespace.id

        result = GitlabSubscriptions::Trials::ApplyTrialService
                   .new(uid: user.id, trial_user_information: trial_user_information_params).execute

        if result.success?
          Gitlab::Tracking.event(self.class.name, 'create_trial', namespace: namespace, user: user)

          ServiceResponse.success(message: 'Trial applied', payload: { namespace: namespace })
        else
          ServiceResponse.error(
            message: result.message, payload: { namespace_id: trial_params[:namespace_id] }, reason: :trial_failed
          )
        end
      end

      def trial_user_information_params
        gl_com_params = { gitlab_com_trial: true, sync_to_gl: true }
        namespace_params = { namespace: namespace.slice(:id, :name, :path, :kind, :trial_ends_on) }

        trial_params.merge(gl_com_params).merge(namespace_params)
      end

      def not_found
        ServiceResponse.error(message: 'Not found', reason: :not_found)
      end
    end
  end
end
