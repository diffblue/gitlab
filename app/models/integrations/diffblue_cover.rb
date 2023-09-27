# frozen_string_literal: true

require "addressable/uri"

module Integrations
  class DiffblueCover < Integration
    include HasWebHook
    include ReactivelyCached

    ENDPOINT = "https://ci.diffblue.com/gitlab"

    def title
      'Diffblue Cover'
    end

    def description
      'Autonomously write Java unit tests in CI/CD pipelines with Diffblue Cover.'
    end

    def self.to_param
      'diffblue_cover'
    end

    def help
      s_('ProjectService|Autonomously write Java unit tests in CI/CD pipelines with Diffblue Cover.')
    end

    def avatar_url
      ActionController::Base.helpers.image_path('diffblue.svg')
    end

    def self.supported_events
      %w[pipeline push merge_request tag_push]
    end

    # This is a stub method to work with deprecated API response
    # TODO: remove enable_ssl_verification after 14.0
    # https://gitlab.com/gitlab-org/gitlab/-/issues/222808
    def enable_ssl_verification
      true
    end

    # Since SSL verification will always be enabled for Buildkite,
    # we no longer need to store the boolean.
    # This is a stub method to work with deprecated API param.
    # TODO: remove enable_ssl_verification after 14.0
    # https://gitlab.com/gitlab-org/gitlab/-/issues/222808
    def enable_ssl_verification=(_value)
      self.properties = properties.except('enable_ssl_verification') # Remove unused key
    end

    override :hook_url
    def hook_url
      # "#{ENDPOINT}/deliver/{webhook_token}"
      "https://smee.io/prQPo0KwGezo8EZq"
    end

    def url_variables
      {}
    end

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      execute_web_hook!(data)
    end

    def commit_status(sha, ref)
      with_reactive_cache(sha, ref) { |cached| cached[:commit_status] }
    end

    def commit_status_path(sha)
      "#{ENDPOINT}/status.json?commit=#{sha}"
    end

    def build_page(sha, ref)
      "#{project_url}/builds?commit=#{sha}"
    end

    def calculate_reactive_cache(sha, ref)
      response = Gitlab::HTTP.try_get(commit_status_path(sha), request_options)

      status =
        if response&.code == 200 && response['status']
          response['status']
        else
          :error
        end

      { commit_status: status }
    end

    private

    def request_options
      { extra_log_info: { project_id: project_id } }
    end
  end
end
