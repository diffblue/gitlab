# frozen_string_literal: true

module CustomDiffHelper
  class << self
    def preprocess_before_diff(path, old_blob, new_blob)
      return unless path.ends_with? '.ipynb'

      transformed_diff = IpynbDiff.diff(old_blob&.data, new_blob&.data,
                                        diff_opts: { context: 5, include_diff_info: true },
                                        transform_options: { cell_decorator: :percent },
                                        raise_if_invalid_notebook: true)
      new_diff = strip_diff_frontmatter(transformed_diff)

      transformed_for_diff(new_blob, old_blob) if new_diff

      Gitlab::AppLogger.info({ message: new_diff ? 'IPYNB_DIFF_GENERATED' : 'IPYNB_DIFF_NIL' })

      new_diff
    rescue IpynbDiff::InvalidNotebookError => e
      Gitlab::ErrorTracking.log_exception(e)
      nil
    end

    def transformed_blob_language(blob)
      'md' if transformed_for_diff?(blob)
    end

    def transformed_blob_data(blob)
      if transformed_for_diff?(blob)
        IpynbDiff.transform(blob.data,
                            raise_errors: true,
                            options: { include_metadata: false, cell_decorator: :percent })
      end
    end

    def strip_diff_frontmatter(diff_content)
      diff_content.scan(/.*\n/)[2..-1]&.join('') if diff_content.present?
    end

    def blobs_with_transformed_diffs
      @blobs_with_transformed_diffs ||= {}
    end

    def transformed_for_diff?(blob)
      blobs_with_transformed_diffs[blob]
    end

    def transformed_for_diff(*blobs)
      blobs.each do |b|
        blobs_with_transformed_diffs[b] = true if b
      end
    end
  end
end
