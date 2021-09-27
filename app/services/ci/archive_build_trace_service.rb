# frozen_string_literal: true

module Ci
  class ArchiveBuildTraceService
    include ::Gitlab::Utils::StrongMemoize
    include Checksummable

    attr_reader :job, :trace_metadata

    def initialize(job, trace_metadata)
      @job = job
      @trace_metadata = trace_metadata
    end

    def execute!(stream)
      clone_file!(stream, JobArtifactUploader.workhorse_upload_path) do |clone_path|
        md5_checksum   = self.class.md5_hexdigest(clone_path)
        trace_artifact = create_build_trace!(job, clone_path)
        trace_metadata.track_archival!(trace_artifact.id, md5_checksum)
      end
    end

    private

    def clone_file!(src_stream, temp_dir)
      FileUtils.mkdir_p(temp_dir)
      Dir.mktmpdir("tmp-trace-#{job.id}", temp_dir) do |dir_path|
        temp_path = File.join(dir_path, "job.log")
        FileUtils.touch(temp_path)
        size = IO.copy_stream(src_stream, temp_path)
        raise ::Gitlab::Ci::Trace::ArchiveError, 'Failed to copy stream' unless size == src_stream.size

        yield(temp_path)
      end
    end

    def create_build_trace!(job, path)
      File.open(path) do |stream|
        # TODO: Set `file_format: :raw` after we've cleaned up legacy traces migration
        # https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/20307
        job.create_job_artifacts_trace!(
          project: job.project,
          file_type: :trace,
          file: stream,
          file_sha256: self.class.sha256_hexdigest(path))
      end
    end
  end
end
