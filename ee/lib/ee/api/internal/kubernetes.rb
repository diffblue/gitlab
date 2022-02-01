# frozen_string_literal: true
module EE
  module API
    module Internal
      module Kubernetes
        extend ActiveSupport::Concern
        prepended do
          namespace 'internal' do
            namespace 'kubernetes' do
              before { check_agent_token }

              helpers do
                def agent_has_access_to_project?(project)
                  project&.licensed_feature_available?(:cluster_agents_gitops) &&
                    (Guest.can?(:download_code, project) || agent.has_access_to?(project))
                end
              end

              desc 'Gets project info' do
                detail 'Retrieves project info (if authorized)'
              end
              route_setting :authentication, cluster_agent_token_allowed: true
              get '/project_info' do
                project = find_project(params[:id])

                not_found! unless agent_has_access_to_project?(project)

                status 200
                {
                  project_id: project.id,
                  gitaly_info: gitaly_info(project),
                  gitaly_repository: gitaly_repository(project)
                }
              end

              namespace 'modules/cilium_alert' do
                desc 'POST network alerts' do
                  detail 'Creates network alert'
                end
                params do
                  requires :alert, type: Hash, desc: 'Alert details'
                end

                route_setting :authentication, cluster_agent_token_allowed: true
                post '/' do
                  project = agent.project

                  not_found! if project.nil?

                  forbidden! unless project.feature_available?(:cilium_alerts)

                  result = ::AlertManagement::NetworkAlertService.new(project, params[:alert]).execute

                  status result.http_status
                end
              end

              namespace 'modules/starboard_vulnerability' do
                desc 'PUT starboard vulnerability' do
                  detail 'Idempotently creates a security vulnerability from starboard'
                end
                params do
                  requires :vulnerability, type: Hash, desc: 'Vulnerability details matching the `vulnerability` object on the security report schema' do
                    requires :name, type: String
                    requires :severity, type: String, coerce_with: ->(s) { s.downcase }
                    requires :confidence, type: String, coerce_with: ->(c) { c.downcase }

                    requires :location, type: Hash do
                      requires :image, type: String

                      requires :dependency, type: Hash do
                        requires :package, type: Hash do
                          requires :name, type: String
                        end

                        optional :version, type: String
                      end

                      requires :kubernetes_resource, type: Hash do
                        requires :namespace, type: String
                        requires :name, type: String
                        requires :kind, type: String
                        requires :container_name, type: String
                        requires :agent_id, type: String
                      end

                      optional :operating_system, type: String
                    end

                    requires :identifiers, type: Array do
                      requires :type, type: String
                      requires :name, type: String
                      optional :value, type: String
                      optional :url, type: String
                    end

                    optional :message, type: String
                    optional :description, type: String
                    optional :solution, type: String
                    optional :links, type: Array
                  end

                  requires :scanner, type: Hash, desc: 'Scanner details matching the `.scan.scanner` field on the security report schema' do
                    requires :id, type: String
                    requires :name, type: String
                    requires :vendor, type: Hash do
                      requires :name, type: String
                    end
                  end
                end

                route_setting :authentication, cluster_agent_token_allowed: true
                put '/' do
                  not_found! if agent.project.nil?

                  result = ::Vulnerabilities::StarboardVulnerabilityCreateService.new(
                    agent,
                    params: params
                  ).execute

                  if result.success?
                    status result.http_status
                    { uuid: result.payload[:vulnerability].finding_uuid }
                  else
                    render_api_error!(result.message, result.http_status)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
