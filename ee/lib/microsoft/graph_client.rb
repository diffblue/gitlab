# frozen_string_literal: true

module Microsoft
  class GraphClient < Gitlab::HTTP
    attr_accessor :access_token, :client_id, :client_secret, :tenant_id, :application

    def initialize(application)
      self.access_token = find_or_initialize_access_token(application)
      self.tenant_id = application.tenant_xid
      self.client_id = application.client_xid
      self.client_secret = application.client_secret
      self.application = application
    end

    def store_new_access_token
      response = self.class.post(
        token_endpoint,
        allow_local_requests: false,
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
        body: URI.encode_www_form(token_endpoint_data)
      )

      return "#{response['error']}: #{response['error_description']}" unless response.success?

      access_token.token = response['access_token']
      access_token.expires_in = response['expires_in']
      access_token.save
    end

    def user_group_memberships(user_id)
      validate_or_update_token!

      self.class.get(user_group_membership_endpoint(user_id), default_request_args)
    end

    def user_group_membership_object_ids(user_id)
      response = user_group_memberships(user_id)
      raw_groups = response['value'] if response['@odata.context'] == directory_odata_context

      return [] unless raw_groups&.any?

      raw_groups.filter_map { |raw_group| raw_group['id'] if raw_group['@odata.type'] == group_odata_type }
    end

    def graph_users_endpoint
      "#{application.graph_endpoint}/v1.0/users"
    end

    def token_endpoint
      "#{application.login_endpoint}/#{tenant_id}/oauth2/v2.0/token"
    end

    def user_group_membership_endpoint(user_id)
      "#{graph_users_endpoint}/#{user_id}/transitiveMemberOf"
    end

    private

    def token_endpoint_data
      {
        client_id: client_id,
        client_secret: client_secret,
        scope: "#{application.graph_endpoint}/.default",
        grant_type: 'client_credentials'
      }
    end

    def default_request_args
      {
        allow_local_requests: false,
        headers: { 'Authorization' => "Bearer #{access_token.token}" }
      }
    end

    def validate_or_update_token!
      return if access_token.updated_at.utc + access_token.expires_in > DateTime.now.utc

      store_new_access_token
    end

    def find_or_initialize_access_token(application)
      application.system_access_microsoft_graph_access_token ||
        application.build_system_access_microsoft_graph_access_token
    end

    def directory_odata_context
      "#{application.graph_endpoint}/v1.0/$metadata#directoryObjects"
    end

    def group_odata_type
      '#microsoft.graph.group'
    end
  end
end
