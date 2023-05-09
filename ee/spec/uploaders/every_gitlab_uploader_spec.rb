# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every GitLab uploader' do
  context 'for Geo replication' do
    # rubocop:disable Layout/LineLength
    it 'has Geo self-service framework support' do
      replicable_names = replicators.map(&:replicable_name)

      missing_data_types = data_types - replicable_names

      expect(missing_data_types)
        .to be_empty, "New uploader type detected: #{missing_data_types.to_a.inspect}. " \
                      "Additional work may be needed to add Geo support. Geo support is " \
                      "a part of the definition of done, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97172. " \
                      "Please visit https://docs.gitlab.com/ee/development/geo.html#ensuring-a-new-feature-has-geo-support " \
                      "for details. If work is not needed, add the uploader to known_unimplemented_uploader? and get a review " \
                      "by a Geo team member."
    end
    # rubocop:enable Layout/LineLength

    def uploaders
      @uploaders ||=
        [].then { |ary| ary.concat(find_uploaders(Rails.root.join('app/uploaders'))) }
          .then { |ary| ary.concat(find_uploaders(Rails.root.join('ee/app/uploaders'))) }
    end

    def find_uploaders(root)
      find_klasses(root, GitlabUploader)
        .reject { |uploader| known_unimplemented_uploader?(uploader) || uploads?(uploader) }
    end

    def replicators
      @replicators ||= find_replicators(Rails.root.join('ee/app/replicators'))
    end

    def find_replicators(root)
      find_klasses(root, Gitlab::Geo::Replicator)
    end

    def find_klasses(root, parent_klass)
      concerns = root.join('concerns').to_s

      Dir[root.join('**', '*.rb')]
        .reject { |path| path.start_with?(concerns) }
        .map    { |path| klass_from_path(path, root) }
        .select { |klass| klass < parent_klass }
    end

    def klass_from_path(path, root)
      ns = Pathname.new(path).relative_path_from(root).to_s.gsub('.rb', '')
      ns.camelize.constantize
    end

    # rubocop:disable Layout/LineLength
    def known_unimplemented_uploader?(uploader)
      {
        DeletedObjectUploader => "Used by Ci::DeletedObject. We don't want to replicate this since the files are physically the same files referenced by Ci::JobArtifact.",
        DependencyProxy::FileUploader => "We do want to replicate this, see https://gitlab.com/groups/gitlab-org/-/epics/8833.",
        Packages::Composer::CacheUploader => "Might not be needed, see https://gitlab.com/gitlab-org/gitlab/-/issues/328491#note_600822092.",
        Packages::Debian::ComponentFileUploader => "This feature is not yet released. We do want to replicate this, see https://gitlab.com/gitlab-org/gitlab/-/issues/333611.",
        Packages::Debian::DistributionReleaseFileUploader => "This feature is not yet released. We do want to replicate this, see https://gitlab.com/gitlab-org/gitlab/-/issues/333615.",
        Packages::Rpm::RepositoryFileUploader => "This feature is not yet released. We do want to replicate this, see https://gitlab.com/gitlab-org/gitlab/-/issues/379055.",
        Packages::Npm::MetadataCacheUploader => "This feature is not yet released. We do want to replicate this, see https://gitlab.com/gitlab-org/gitlab/-/issues/408278."
      }.key?(uploader)
    end
    # rubocop:enable Layout/LineLength

    def uploads?(uploader)
      upload_name = uploader.name.delete_suffix('Uploader').underscore
      Gitlab::Geo::Replication.object_type_from_user_uploads?(upload_name)
    end

    def data_types
      @data_types ||= uploaders.map { |uploader| data_type_for(uploader) }
    end

    def data_type_for(uploader)
      object_type = uploader.name.delete_suffix('Uploader').underscore.tr('/', '_')

      unmatched_data_types = {
        'ci_pipeline_artifact' => 'pipeline_artifact',
        'external_diff' => 'merge_request_diff',
        'packages_package_file' => 'package_file',
        'terraform_state' => 'terraform_state_version'
      }

      unmatched_data_types.fetch(object_type, object_type)
    end
  end
end
