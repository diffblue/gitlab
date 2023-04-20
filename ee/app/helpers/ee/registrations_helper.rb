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

    private

    def redirect_path
      strong_memoize(:redirect_path) do
        # we use direct session here since stored_location_for
        # will delete the value upon fetching
        redirect_to = session['user_return_to']
        URI.parse(redirect_to).path if redirect_to
      end
    end

    def registration_objective_options
      localized_jobs_to_be_done_choices.dup
    end
  end
end
