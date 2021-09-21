# frozen_string_literal: true

module EE
  module RegistrationsHelper
    include ::Gitlab::Utils::StrongMemoize
    extend ::Gitlab::Utils::Override

    override :signup_username_data_attributes
    def signup_username_data_attributes
      super.merge(api_path: suggestion_path)
    end

    def shuffled_jobs_to_be_done_options
      jobs_to_be_done_options.shuffle.append([_('A different reason'), 'other'])
    end

    private

    def redirect_path
      strong_memoize(:redirect_path) do
        redirect_to = session['user_return_to']
        URI.parse(redirect_to).path if redirect_to
      end
    end

    def jobs_to_be_done_options
      [
        _('I want to learn the basics of Git'),
        _('I want to move my repository to GitLab from somewhere else'),
        _('I want to store my code'),
        _('I want to explore GitLab to see if it’s worth switching to'),
        _('I want to use GitLab CI with my existing repository'),
        _('I’m joining my team who’s already on GitLab')
      ]
    end
  end
end
