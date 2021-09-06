# frozen_string_literal: true

module Registrations::CreateGroup
  extend ActiveSupport::Concern

  included do
    before_action :check_if_gl_com_or_dev
    before_action :authorize_create_group!, only: :new

    protected

    def show_confirm_warning?
      false
    end

    private

    def authorize_create_group!
      access_denied! unless can?(current_user, :create_group)
    end

    def group_params
      params.require(:group).permit(:name, :path, :visibility_level)
    end

    def learn_gitlab_context
      strong_memoize(:learn_gitlab_context) do
        in_experiment_group_a = Gitlab::Experimentation.in_experiment_group?(:learn_gitlab_a, subject: current_user)
        in_experiment_group_b = !in_experiment_group_a && Gitlab::Experimentation.in_experiment_group?(:learn_gitlab_b, subject: current_user)

        { in_experiment_group_a: in_experiment_group_a, in_experiment_group_b: in_experiment_group_b }
      end
    end
  end
end
