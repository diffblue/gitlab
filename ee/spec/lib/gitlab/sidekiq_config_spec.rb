# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqConfig do
  describe '.workers' do
    it 'includes EE workers' do
      worker_classes = described_class.workers.map(&:klass)

      expect(worker_classes).to include(RepositoryUpdateMirrorWorker)
      expect(worker_classes).to include(LdapGroupSyncWorker)
    end
  end

  describe '.worker_queues' do
    it 'includes EE queues' do
      queues = described_class.worker_queues

      expect(queues).to include('repository_update_mirror')
      expect(queues).to include('ldap_group_sync')
    end
  end

  describe '.expand_queues' do
    it 'expands queue namespaces to concrete queue names' do
      queues = described_class.expand_queues(%w[cronjob])

      expect(queues).to include('cronjob:import_stuck_project_import_jobs')
      expect(queues).to include('cronjob:jira_import_stuck_jira_import_jobs')
      expect(queues).to include('cronjob:stuck_merge_jobs')
    end

    it 'lets concrete queue names pass through' do
      queues = described_class.expand_queues(%w[post_receive])

      expect(queues).to include('post_receive')
    end

    it 'lets unknown queues pass through' do
      queues = described_class.expand_queues(%w[unknown])

      expect(queues).to include('unknown')
    end
  end

  describe '.workers_for_all_queues_yml' do
    it 'returns a tuple with EE workers second' do
      expect(described_class.workers_for_all_queues_yml.second)
        .to include(an_object_having_attributes(generated_queue_name: 'repository_update_mirror'))
    end
  end

  describe '.all_queues_yml_outdated?' do
    let(:workers) do
      [
        LdapGroupSyncWorker,
        RepositoryUpdateMirrorWorker
      ].map { |worker| described_class::Worker.new(worker, ee: true) }
    end

    before do
      allow(described_class).to receive(:workers).and_return(workers)
      allow(Gitlab).to receive(:jh?).and_return(false)

      allow(YAML).to receive(:load_file)
                       .with(described_class::FOSS_QUEUE_CONFIG_PATH)
                       .and_return([])
    end

    it 'returns true if the YAML file does not match the application code' do
      allow(YAML).to receive(:load_file)
                       .with(described_class::EE_QUEUE_CONFIG_PATH)
                       .and_return([workers.first.to_yaml])

      expect(described_class.all_queues_yml_outdated?).to be(true)
    end

    it 'returns false if the YAML file matches the application code' do
      allow(YAML).to receive(:load_file)
                       .with(described_class::EE_QUEUE_CONFIG_PATH)
                       .and_return(workers.map(&:to_yaml))

      expect(described_class.all_queues_yml_outdated?).to be(false)
    end
  end
end
