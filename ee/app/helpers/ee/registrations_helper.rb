# frozen_string_literal: true

module EE
  module RegistrationsHelper
    include ::Gitlab::Utils::StrongMemoize
    extend ::Gitlab::Utils::Override

    def shuffled_registration_objective_options
      options = registration_objective_options
      other = options.extract!(:other).to_a.flatten
      options.to_a.shuffle.append(other).map { |option| option.reverse }
    end

    def arkose_labs_data
      {
        api_key: Arkose::Settings.arkose_public_api_key,
        domain: Arkose::Settings.arkose_labs_domain
      }
    end

    override :register_omniauth_params
    def register_omniauth_params(local_assigns)
      super.merge(glm_tracking_params.to_h).merge(local_assigns.slice(:trial))
    end

    private

    def registration_objective_options
      localized_jobs_to_be_done_choices.dup
    end
  end
end
