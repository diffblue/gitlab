# frozen_string_literal: true

module API
  class Experiments < ::API::Base
    before { authorize_read_experiments! }

    feature_category :acquisition

    resource :experiments do
      desc 'List all experiments' do
        detail 'Get a list of all experiments. Each experiment has an enabled status that indicates whether'\
          'the experiment is enabled globally, or only in specific contexts.'
        success EE::API::Entities::Experiment
        is_array true
        tags %w[experiments]
      end
      get do
        experiments = []

        experiment(:null_hypothesis, canary: true, user: current_user) do |e|
          e.control { bad_request! 'experimentation may not be working right now' }
          e.candidate do
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
