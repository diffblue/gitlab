# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportIssueEventsWorker do
  let(:project) { create(:project) }
  let(:import_state) { create(:import_state, project: project) }
  let(:worker) { described_class.new }

  describe '#import' do
    let(:importer) { instance_double('Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter') }
    let(:client) { instance_double('Gitlab::GithubImport::Client') }

    it 'imports all the pull requests' do
      waiter = Gitlab::JobWaiter.new(2, '123')

      expect(Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter)
        .to receive(:new)
        .with(project, client)
        .and_return(importer)

      expect(importer).to receive(:execute).and_return(waiter)

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2 }, :notes)

      worker.import(client, project)
    end
  end
end
