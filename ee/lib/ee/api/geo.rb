# frozen_string_literal: true

require 'base64'

module EE
  module API
    module Geo
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          def sanitized_node_status_params
            valid_attributes = GeoNodeStatus.attribute_names - GeoNodeStatus::RESOURCE_STATUS_FIELDS - ['id']
            sanitized_params = params.slice(*valid_attributes)

            # sanitize status field
            sanitized_params['status'] = sanitized_params['status'].slice(*GeoNodeStatus::RESOURCE_STATUS_FIELDS) if sanitized_params['status']

            sanitized_params
          end

          # Check if a Geo request is legit or fail the flow
          #
          # @param [Hash] attributes to be matched against JWT
          def authorize_geo_transfer!(**attributes)
            unauthorized! unless geo_jwt_decoder.valid_attributes?(**attributes)
          end

          override :geo_proxy_response
          def geo_proxy_response
            # The methods used here (or their underlying methods) are cached
            # for:
            #
            # * 1 minute in memory
            # * 2 minutes in Redis
            #
            # The cached values are invalidated when changed.
            #
            non_proxy_response = super.merge({ geo_enabled: ::Gitlab::Geo.enabled? })

            return non_proxy_response unless ::Gitlab::Geo.secondary_with_primary?

            return non_proxy_response unless ::Gitlab::Geo.secondary_with_unified_url? ||
                                             ::Feature.enabled?(:geo_secondary_proxy_separate_urls)

            non_proxy_response.merge({
              geo_proxy_url: ::Gitlab::Geo.primary_node.internal_url,
              geo_proxy_extra_data: ::Gitlab::Geo.proxy_extra_data
            })
          end
        end

        resource :geo do
          params do
            requires :replicable_name, type: String, desc: 'Replicable name (eg. package_file)'
            requires :replicable_id, type: Integer, desc: 'The replicable ID that needs to be transferred'
          end
          get 'retrieve/:replicable_name/:replicable_id' do
            check_gitlab_geo_request_ip!
            params_sym = params.symbolize_keys
            authorize_geo_transfer!(**params_sym)

            decoded_params = geo_jwt_decoder.decode
            service = ::Geo::BlobUploadService.new(**params_sym, decoded_params: decoded_params)
            response = service.execute

            if response[:code] == :ok
              file = response[:file]
              present_carrierwave_file!(file)
            else
              error! response, response.delete(:code)
            end
          end

          # Post current node information to primary (e.g. health, repos synced, repos failed, etc.)
          #
          # Example request:
          #   POST /geo/status
          post 'status' do
            check_gitlab_geo_request_ip!
            authenticate_by_gitlab_geo_node_token!

            db_status = GeoNode.find(params[:geo_node_id]).find_or_build_status

            unless db_status.update(sanitized_node_status_params.merge(last_successful_status_check_at: Time.now.utc))
              render_validation_error!(db_status)
            end
          end

          # git over SSH secondary endpoints -> primary related proxying logic
          #
          resource 'proxy_git_ssh' do
            format :json

            # For git clone/pull

            # Responsible for making HTTP GET /repo.git/info/refs?service=git-upload-pack
            # request *from* secondary gitlab-shell to primary
            #
            params do
              requires :secret_token, type: String
              requires :data, type: Hash do
                requires :gl_id, type: String
                requires :primary_repo, type: String
              end
            end
            post 'info_refs_upload_pack' do
              authenticate_by_gitlab_shell_token!
              params.delete(:secret_token)

              response = ::Gitlab::Geo::GitSSHProxy.new(params['data']).info_refs_upload_pack

              status(response.code)
              response.body
            end

            # Responsible for making HTTP POST /repo.git/git-upload-pack
            # request *from* secondary gitlab-shell to primary
            #
            params do
              requires :secret_token, type: String
              requires :data, type: Hash do
                requires :gl_id, type: String
                requires :primary_repo, type: String
              end
              requires :output, type: String, desc: 'Output from git-upload-pack'
            end
            post 'upload_pack' do
              authenticate_by_gitlab_shell_token!
              params.delete(:secret_token)

              response = ::Gitlab::Geo::GitSSHProxy.new(params['data']).upload_pack(params['output'])

              status(response.code)
              response.body
            end

            # For git push

            # Responsible for making HTTP GET /repo.git/info/refs?service=git-receive-pack
            # request *from* secondary gitlab-shell to primary
            #
            params do
              requires :secret_token, type: String
              requires :data, type: Hash do
                requires :gl_id, type: String
                requires :primary_repo, type: String
              end
            end
            post 'info_refs_receive_pack' do
              authenticate_by_gitlab_shell_token!
              params.delete(:secret_token)

              response = ::Gitlab::Geo::GitSSHProxy.new(params['data']).info_refs_receive_pack
              status(response.code)
              response.body
            end

            # Responsible for making HTTP POST /repo.git/git-receive-pack
            # request *from* secondary gitlab-shell to primary
            #
            params do
              requires :secret_token, type: String
              requires :data, type: Hash do
                requires :gl_id, type: String
                requires :primary_repo, type: String
              end
              requires :output, type: String, desc: 'Output from git-receive-pack'
            end
            post 'receive_pack' do
              authenticate_by_gitlab_shell_token!
              params.delete(:secret_token)

              response = ::Gitlab::Geo::GitSSHProxy.new(params['data']).receive_pack(params['output'])
              status(response.code)
              response.body
            end
          end

          resource 'node_proxy' do
            before do
              authenticated_as_admin!
            end

            route_param :id, type: Integer, desc: 'The ID of the Geo node' do
              helpers do
                def geo_node
                  strong_memoize(:geo_node) { GeoNode.find(params[:id]) }
                end
              end

              # Query the graphql endpoint of an existing Geo node
              #
              # Example request:
              #   POST /geo/node_proxy/:id/graphql
              desc 'Query the graphql endpoint of a specific Geo node'
              post 'graphql' do
                not_found!('GeoNode') unless geo_node

                body = env['api.request.input']

                status 200
                ::Geo::GraphqlRequestService.new(geo_node, current_user).execute(body) || {}
              end
            end
          end
        end
      end
    end
  end
end
