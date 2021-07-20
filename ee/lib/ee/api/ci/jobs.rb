# frozen_string_literal: true

module EE
  module API
    module Ci
      module Jobs
        extend ActiveSupport::Concern

        prepended do
          resource :job do
            desc 'Get current agents' do
              detail 'Retrieves a list of agents for the given job token'
            end
            route_setting :authentication, job_token_allowed: true
            get '/allowed_agents', feature_category: :kubernetes_management do
              validate_current_authenticated_job

              status 200

              pipeline = current_authenticated_job.pipeline
              project = current_authenticated_job.project
              allowed_agents = ::Clusters::DeployableAgentsFinder.new(project).execute

              {
                allowed_agents: ::API::Entities::Clusters::Agent.represent(allowed_agents),
                job: ::API::Entities::Ci::JobRequest::JobInfo.represent(current_authenticated_job),
                pipeline: ::API::Entities::Ci::PipelineBasic.represent(pipeline),
                project: ::API::Entities::ProjectIdentity.represent(project),
                user: ::API::Entities::UserBasic.represent(current_user)
              }
            end
          end
        end
      end
    end
  end
end
