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
                    requires :severity, type: String
                    requires :confidence, type: String
                    requires :location, type: Hash
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

                    optional :vendor, type: String
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
