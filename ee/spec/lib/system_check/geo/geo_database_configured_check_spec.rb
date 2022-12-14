# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::Geo::GeoDatabaseConfiguredCheck, :silence_stdout, feature_category: :geo_replication do
  subject { described_class.new }

  describe '#multi_check', :reestablished_active_record_base do
    it "checks database configuration" do
      stub_database_state(subject, configured: false)

      expect(subject).to receive(:try_fixing_it).with(described_class::WRONG_CONFIGURATION_MESSAGE)
      expect(subject.multi_check).to be_falsey
    end

    it "checks database configuration" do
      stub_database_state(subject, active: false)

      expect(subject).to receive(:try_fixing_it).with(described_class::UNHEALTHY_CONNECTION_MESSAGE)

      expect(subject.multi_check).to be_falsey
    end

    it "checks table existence" do
      stub_database_state(subject, tables: false)

      expect(subject).to receive(:try_fixing_it).with(described_class::NO_TABLES_MESSAGE)

      expect(subject.multi_check).to be_falsey
    end

    it "checks if existing database is being reused" do
      stub_database_state(subject, fresh: false)

      expect(subject).to receive(:try_fixing_it).with(described_class::REUSING_EXISTING_DATABASE_MESSAGE)

      expect(subject.multi_check).to be_falsey
    end

    it "returns true when all checks passed" do
      stub_database_state(subject)

      expect(subject).not_to receive(:try_fixing_it)

      expect(subject.multi_check).to be_truthy
    end
  end

  def stub_database_state(subject, configured: true, active: true, tables: true, fresh: true)
    allow(subject).to receive(:needs_migration?).and_return(!tables)

    allow(::Gitlab::Geo).to receive(:geo_database_configured?).and_return(configured)
    allow(::Geo::TrackingBase).to receive(:connection).and_return(double(active?: active))

    allow_next_instance_of(::Gitlab::Geo::HealthCheck) do |health_check|
      allow(health_check).to receive(:reusing_existing_tracking_database?).and_return(!fresh)
    end
  end
end
