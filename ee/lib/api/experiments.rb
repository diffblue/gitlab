# frozen_string_literal: true

module API
  class Experiments < ::API::Base
    before { authorize_read_experiments! }

    feature_category :experimentation_expansion

    resource :experiments do
      desc 'Get a list of all experiments' do
        success EE::API::Entities::Experiment
      end
      get do
        experiments = []

        experiment(:null_hypothesis, canary: true, user: current_user) do |e|
          e.use { bad_request! 'experimentation may not be working right now' }
          e.try do
            experiments = Feature::Definition.definitions.values.select { |d| d.attributes[:type] == 'experiment' }
          end
        end

        present experiments, with: EE::API::Entities::Experiment, current_user: current_user
      end
    end

    helpers do
      include Gitlab::Experiment::Dsl

      def authorize_read_experiments!
        authenticate!

        forbidden! unless current_user.gitlab_team_member?
      end
    end
  end
end
