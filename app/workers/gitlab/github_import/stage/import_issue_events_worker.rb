# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportIssueEventsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        sidekiq_options retry: 3
        include GithubImport::Queue
        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          importer = ::Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter
          info(project.id, message: "starting importer", importer: importer.name)
          waiter = importer.new(project, client).execute

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            :notes
          )
        end
      end
    end
  end
end
