# frozen_string_literal: true

class PseudonymizerWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :integrations

  def perform
    return unless Gitlab::CurrentSettings.pseudonymizer_enabled?

    options = Pseudonymizer::Options.new(
      config: YAML.load_file(Gitlab.config.pseudonymizer.manifest),
      output_dir: ENV['PSEUDONYMIZER_OUTPUT_DIR']
    )

    dumper = Pseudonymizer::Dumper.new(options)
    uploader = Pseudonymizer::Uploader.new(options, progress_output: File.open(File::NULL, "w"))

    unless uploader.available?
      Gitlab::AppLogger.error("The pseudonymizer object storage must be configured.")
      return
    end

    begin
      dumper.tables_to_csv
      uploader.upload
    ensure
      uploader.cleanup
    end
  end
end
