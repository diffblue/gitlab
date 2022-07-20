# frozen_string_literal: true

module Gitlab
  module Ci
    class RunnerUpgradeCheck
      include Singleton

      def check_runner_upgrade_suggestion(runner_version)
        check_runner_upgrade_suggestions(runner_version).first
      end

      private

      def check_runner_upgrade_suggestions(runner_version)
        runner_version = ::Gitlab::VersionInfo.parse(runner_version, parse_suffix: true)

        return { runner_version => :invalid_version } unless runner_version.valid?
        return { runner_version => :error } unless runner_releases_store.releases

        suggestions = {}

        # Recommend update if outside of backport window
        recommended_version = recommendation_if_outside_backport_window(runner_version)
        if recommended_version
          suggestions[recommended_version] = :recommended
        else
          # Recommend patch update if there's a newer release in a same minor branch as runner
          recommended_version = recommended_runner_release_update(runner_version)
          suggestions[recommended_version] = :recommended if recommended_version
        end

        # Consider update if there's a newer release within the currently deployed GitLab version
        available_version = available_runner_release(runner_version)
        if available_version && !suggestions.include?(available_version)
          suggestions[available_version] = :available
        end

        suggestions[runner_version] = :not_available if suggestions.empty?

        suggestions
      end

      def recommended_runner_release_update(runner_version)
        recommended_release = runner_releases_store.releases_by_minor[runner_version.without_patch]
        return recommended_release if recommended_release && recommended_release > runner_version

        # Consider the edge case of pre-release runner versions that get registered, but are never published.
        # In this case, suggest the latest compatible runner version
        latest_release = runner_releases_store.releases_by_minor.values.select { |v| v < gitlab_version }.max
        latest_release if latest_release && latest_release > runner_version
      end

      def available_runner_release(runner_version)
        available_release = runner_releases_store.releases_by_minor[gitlab_version.without_patch]
        available_release if available_release && available_release > runner_version
      end

      def gitlab_version
        @gitlab_version ||= ::Gitlab::VersionInfo.parse(::Gitlab::VERSION, parse_suffix: true)
      end

      def runner_releases_store
        RunnerReleases.instance
      end

      def recommendation_if_outside_backport_window(runner_version)
        return if runner_releases_store.releases.empty?
        return if runner_version >= runner_releases_store.releases.last # return early if runner version is too new

        minor_releases_with_index = runner_releases_store.releases_by_minor.keys.each_with_index.to_h
        runner_minor_version_index = minor_releases_with_index[runner_version.without_patch]
        if runner_minor_version_index
          # https://docs.gitlab.com/ee/policy/maintenance.html#backporting-to-older-releases
          outside_window = minor_releases_with_index.count - runner_minor_version_index > 3

          if outside_window
            recommended_release = runner_releases_store.releases_by_minor[gitlab_version.without_patch]

            recommended_release if recommended_release && recommended_release > runner_version
          end
        else
          # If unknown runner version, then recommend the latest version for the GitLab instance
          recommended_runner_release_update(gitlab_version)
        end
      end
    end
  end
end
