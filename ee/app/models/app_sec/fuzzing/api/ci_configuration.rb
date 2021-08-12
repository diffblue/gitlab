# frozen_string_literal: true

module AppSec
  module Fuzzing
    module API
      class CiConfiguration
        PROFILES_DEFINITION_FILE = 'https://gitlab.com/gitlab-org/security-products/analyzers' \
          '/api-fuzzing/-/raw/master/gitlab-api-fuzzing-config.yml'
        SCAN_MODES = [:har, :openapi, :postman].freeze
        SCAN_PROFILES_CACHE_KEY = 'app_sec:fuzzing:api:scan_profiles'

        def initialize(project:)
          @project = project
        end

        def scan_profiles
          scan_profiles_data.map do |profile|
            next unless ScanProfile::NAMES.include?(profile[:Name])

            ScanProfile.new(
              name: profile[:Name],
              project: project,
              yaml: profile.deep_stringify_keys.to_yaml
            )
          end.compact
        end

        private

        attr_reader :project

        def scan_profiles_data
          Rails.cache.fetch(SCAN_PROFILES_CACHE_KEY, expires_in: 1.hour) do
            fetch_scan_profiles
          end
        end

        def fetch_scan_profiles
          response = Gitlab::HTTP.try_get(PROFILES_DEFINITION_FILE)

          if response&.success?
            content = Gitlab::Config::Loader::Yaml.new(response.body).load!

            content.fetch(:Profiles, [])
          else
            []
          end
        end
      end
    end
  end
end
