# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every GitLab uploader' do
  context 'Geo replication' do
    # The Geo legacy replication requires every GitLab uploader class to have a valid file retriever/downloader
    # class for the given object_type. If you are adding a new uploader or a new usage of an uploader, it may
    # require work to add support for it in Geo. Please notify the Geo team. For an example of the problem, see
    # https://gitlab.com/gitlab-org/gitlab/-/issues/328223.
    context 'legacy replication' do
      it 'has a valid file retriever class for the given object_type', :aggregate_failures do
        object_types.each do |object_type|
          subject = Geo::FileUploadService.new({ type: object_type, id: 1 }, 'request-data')

          expect { subject.retriever }.not_to raise_error
        end
      end

      it 'has a valid file downloader class for the given object_type', :aggregate_failures do
        object_types.each do |object_type|
          subject = Geo::FileDownloadService.new(object_type, 1)

          expect { subject.downloader }.not_to raise_error
        end
      end
    end

    context 'Geo self-service framework' do
      # When this test starts failing means that we have migrated Geo's handling of uploads to the
      # SSF, and we can remove the tests for the file retriever and downloader classes.
      it 'has some uploads to be migrated' do
        stub_feature_flags(geo_job_artifact_replication: false)

        expect(object_types - replicable_names).not_to be_empty
      end
    end

    def uploaders
      @uploaders ||= begin
        result = []
        result.concat(find_uploaders(Rails.root.join('app', 'uploaders')))
        result.concat(find_uploaders(Rails.root.join('ee', 'app', 'uploaders')))
      end
    end

    def find_uploaders(root)
      find_klasses(root, GitlabUploader)
        .reject { |uploader| known_unimplemented_uploader?(uploader) || handled_by_ssf?(uploader) }
    end

    def replicators
      @replicators ||= find_replicators(Rails.root.join('ee', 'app', 'replicators'))
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

    # Please see https://gitlab.com/gitlab-org/gitlab/-/issues/328491 for more details.
    def known_unimplemented_uploader?(uploader)
      [
        Ci::SecureFileUploader, # TODO: Add Geo support for Secure Files https://gitlab.com/gitlab-org/gitlab/-/issues/349893
        DeletedObjectUploader,
        DependencyProxy::FileUploader,
        Packages::Composer::CacheUploader,
        Packages::Debian::ComponentFileUploader,
        Packages::Debian::DistributionReleaseFileUploader,
        Pages::DeploymentUploader,
        Terraform::StateUploader
      ].include?(uploader)
    end

    def handled_by_ssf?(uploader)
      return true if uploads?(uploader)

      replicable_name = replicable_name_for(uploader)
      replicable_names.include?(replicable_name) && ::Gitlab::Geo::Replicator.for_replicable_name(replicable_name).enabled?
    end

    def uploads?(uploader)
      upload_name = uploader.name.delete_suffix('Uploader').underscore
      Gitlab::Geo::Replication.object_type_from_user_uploads?(upload_name)
    end

    def object_types
      @object_types ||= uploaders.map { |uploader| object_type_for(uploader) }
    end

    def object_type_for(uploader)
      object_type = uploader.name.delete_suffix('Uploader').underscore

      unmatched_object_types = {
        'lfs_object' => 'lfs'
      }

      unmatched_object_types.fetch(object_type, object_type)
    end

    def replicable_names
      @replicable_names ||= begin
        replicators
          .map(&:replicable_name)
          .select {|replicable_name| ::Gitlab::Geo::Replicator.for_replicable_name(replicable_name).enabled? }
      end
    end

    def replicable_name_for(uploader)
      replicable_name = uploader.name.demodulize.delete_suffix('Uploader').underscore

      unmatched_replicable_names = {
        'external_diff' => 'merge_request_diff'
      }

      unmatched_replicable_names.fetch(replicable_name, replicable_name)
    end
  end
end
