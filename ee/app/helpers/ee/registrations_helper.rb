# frozen_string_literal: true

module EE
  module RegistrationsHelper
    include ::Gitlab::Utils::StrongMemoize
    extend ::Gitlab::Utils::Override

    override :signup_username_data_attributes
    def signup_username_data_attributes
      super.merge(api_path: suggestion_path)
    end

    def shuffled_registration_objective_options
      options = registration_objective_options
      other = options.extract!(:other).to_a.flatten
      options.to_a.shuffle.append(other).map { |option| option.reverse }
    end

    private

    def redirect_path
      strong_memoize(:redirect_path) do
        redirect_to = session['user_return_to']
        URI.parse(redirect_to).path if redirect_to
      end
    end

    def registration_objective_options
      options = localized_jobs_to_be_done_choices.dup

      experiment(:bypass_registration, user: current_user) do |e|
        e.use do
          options.merge(
            joining_team: _('I’m joining my team who’s already on GitLab')
          )
        end
        e.try do
          options
        end
        e.run
      end
    end
  end
end
