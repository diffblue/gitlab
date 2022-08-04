# frozen_string_literal: true

module RunnerReleasesHelper
  def stub_runner_releases(runner_releases_double, available_runner_releases, gitlab_version:)
    # We stub the behavior of RunnerReleases so that we don't need to rely on flaky global settings
    available_runner_releases = available_runner_releases
      .map { |v| ::Gitlab::VersionInfo.parse(v, parse_suffix: true) }
      .sort
    releases_by_minor = available_runner_releases
      .group_by(&:without_patch)
      .transform_values(&:max)

    allow(::Gitlab::Ci::RunnerUpgradeCheck).to receive(:new).and_wrap_original do |method, *_original_args|
      method.call(gitlab_version, runner_releases_double)
    end

    allow(runner_releases_double).to receive(:releases).and_return(available_runner_releases)
    allow(runner_releases_double).to receive(:releases_by_minor).and_return(releases_by_minor)
  end
end
