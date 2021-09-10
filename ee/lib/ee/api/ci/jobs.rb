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

              allowed_agents =
                if ::Feature.enabled?(:group_authorized_agents, project, default_enabled: :yaml)
                  agent_authorizations = ::Clusters::AgentAuthorizationsFinder.new(project).execute
                  ::API::Entities::Clusters::AgentAuthorization.represent(agent_authorizations)
                else
                  associated_agents = ::Clusters::DeployableAgentsFinder.new(project).execute
                  ::API::Entities::Clusters::Agent.represent(associated_agents)
                end

              {
                allowed_agents: allowed_agents,
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
