# frozen_string_literal: true

module ProductAnalytics
  class JitsuAuthentication
    def initialize(jid, project)
      @jid = jid
      @project = project

      settings = ProductAnalytics::Settings.for_project(project)
      @root_url = settings.jitsu_host
      @clickhouse_connection_string = settings.product_analytics_clickhouse_connection_string
      @jitsu_project_xid = settings.jitsu_project_xid
      @jitsu_administrator_email = settings.jitsu_administrator_email
      @jitsu_administrator_password = settings.jitsu_administrator_password
    end

    def create_api_key!
      response = Gitlab::HTTP.post(
        "#{@root_url}/api/v2/objects/#{@jitsu_project_xid}/api_keys",
        allow_local_requests: true,
        headers: {
          Authorization: "Bearer #{generate_access_token}"
        },
        body: {
          'comment': @project.to_global_id.to_s,
          'jsAuth': SecureRandom.uuid
        }.to_json
      )

      json = Gitlab::Json.parse(response.body)

      if response.success?
        @project.project_setting.update(jitsu_key: json['jsAuth'])

        return { jsAuth: json['jsAuth'], uid: json['uid'] }
      end

      log_jitsu_api_error(json)
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
    end

    def create_clickhouse_destination!
      id = SecureRandom.uuid

      response = Gitlab::HTTP.post(
        "#{@root_url}/api/v2/objects/#{@jitsu_project_xid}/destinations",
        allow_local_requests: true,
        headers: {
          Authorization: "Bearer #{generate_access_token}"
        },
        body: {
          _type: 'clickhouse',
          _onlyKeys: [create_api_key![:uid]],
          _id: id,
          _uid: SecureRandom.uuid,
          _connectionTestOk: true,
          _formData: {
            ch_database: "gitlab_project_#{@project.id}",
            mode: 'stream',
            tableName: "jitsu",
            ch_dsns_list: [@clickhouse_connection_string]
          }
        }.to_json
      )

      response.success? ? id : log_jitsu_api_error(Gitlab::Json.parse(response.body))
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
    end

    def generate_access_token
      response = Gitlab::HTTP.post(
        "#{@root_url}/api/v1/users/signin",
        allow_local_requests: true,
        headers: { 'Content-Type' => 'application/json' },
        body: {
          'email': @jitsu_administrator_email,
          'password': @jitsu_administrator_password
        }.to_json
      )

      json = Gitlab::Json.parse(response.body)

      response.success? ? json['access_token'] : log_jitsu_api_error(json)
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
    end

    private

    def log_jitsu_api_error(json)
      Gitlab::AppLogger.error(
        message: 'Jitsu API error',
        error: json['error'],
        jitsu_error_message: json['message'],
        project_id: @project.id,
        job_id: @jid
      )
    end
  end
end
