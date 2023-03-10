# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::CronManager, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  jobs = %w[
    ldap_test
    repository_check_worker
    geo_repository_verification_primary_batch_worker
    geo_repository_sync_worker
    geo_registry_sync_worker
    geo_repository_registry_sync_worker
    geo_repository_verification_secondary_scheduler_worker
    geo_metrics_update_worker
    geo_prune_event_log_worker
    geo_verification_cron_worker
    geo_secondary_usage_data_cron_worker
    geo_sync_timeout_cron_worker
  ].freeze

  def job(name)
    Sidekiq::Cron::Job.find(name)
  end

  subject(:manager) { described_class.new }

  describe '#execute' do
    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }

    let(:common_geo_jobs) { [job('geo_metrics_update_worker'), job('geo_verification_cron_worker')] }
    let(:ldap_test_job) { job('ldap_test') }
    let(:primary_jobs) { [job('geo_repository_verification_primary_batch_worker')] }
    let(:repository_check_job) { job('repository_check_worker') }

    let(:secondary_jobs) do
      [
        job('geo_registry_sync_worker'),
        job('geo_repository_registry_sync_worker'),
        job('geo_repository_sync_worker'),
        job('geo_repository_verification_secondary_scheduler_worker'),
        job('geo_secondary_usage_data_cron_worker'),
        job('geo_sync_timeout_cron_worker')
      ]
    end

    before(:all) do
      jobs.each { |name| init_cron_job(name, name.camelize) }
    end

    after(:all) do
      jobs.each { |name| job(name)&.destroy } # rubocop: disable Rails/SaveBang
    end

    def init_cron_job(job_name, class_name)
      job = Sidekiq::Cron::Job.new(
        name: job_name,
        cron: '0 * * * *',
        class: class_name
      )

      job.enable!
    end

    def count_enabled(jobs)
      jobs.count { |job_name| job(job_name).enabled? }
    end

    context 'on a Geo primary' do
      before do
        stub_current_geo_node(primary)

        manager.execute
      end

      it 'disables secondary-only jobs' do
        secondary_jobs.each { |job| expect(job).not_to be_enabled }
      end

      it 'enables common Geo jobs' do
        expect(common_geo_jobs).to all(be_enabled)
      end

      it 'enables primary-only jobs' do
        expect(primary_jobs).to all(be_enabled)
      end

      it 'enables repository check job' do
        expect(repository_check_job).to be_enabled
      end

      it 'enables non-geo jobs' do
        expect(ldap_test_job).to be_enabled
      end

      context 'No connection' do
        it 'does not change current job configuration' do
          allow(Geo).to receive(:connected?).and_return(false)

          expect { manager.execute }.not_to change { count_enabled(jobs) }
        end
      end
    end

    context 'on a Geo secondary' do
      before do
        stub_current_geo_node(secondary)

        manager.execute
      end

      it 'enables secondary-only jobs' do
        expect(secondary_jobs).to all(be_enabled)
      end

      it 'enables common Geo jobs' do
        expect(common_geo_jobs).to all(be_enabled)
      end

      it 'enables repository check job' do
        expect(repository_check_job).to be_enabled
      end

      it 'disables primary-only jobs' do
        primary_jobs.each { |job| expect(job).not_to be_enabled }
      end

      it 'disables non-geo jobs' do
        expect(ldap_test_job).not_to be_enabled
      end
    end

    context 'on a non-Geo node' do
      before do
        stub_current_geo_node(nil)

        manager.execute
      end

      it 'disables primary-only jobs' do
        primary_jobs.each { |job| expect(job).not_to be_enabled }
      end

      it 'disables secondary-only jobs' do
        secondary_jobs.each { |job| expect(job).not_to be_enabled }
      end

      it 'disables common Geo jobs' do
        common_geo_jobs.each { |job| expect(job).not_to be_enabled }
      end

      it 'enables repository check job' do
        expect(repository_check_job).to be_enabled
      end

      it 'enables non-geo jobs' do
        expect(ldap_test_job).to be_enabled
      end
    end
  end

  describe '#create_watcher!' do
    it 'creates a Geo::SidekiqCronConfigWorker sidekiq-cron job' do
      manager.create_watcher!

      created = job('geo_sidekiq_cron_config_worker')

      expect(created).not_to be_nil
      expect(created.klass).to eq('Geo::SidekiqCronConfigWorker')
      expect(created.cron).to eq('*/1 * * * *')
      expect(created.name).to eq('geo_sidekiq_cron_config_worker')
    end
  end
end
