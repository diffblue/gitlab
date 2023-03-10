# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::RakeTask::GeoTask, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let(:common_checks) do
    [
      SystemCheck::Geo::LicenseCheck,
      SystemCheck::Geo::EnabledCheck,
      SystemCheck::Geo::CurrentNodeCheck,
      SystemCheck::Geo::HTTPCloneEnabledCheck,
      SystemCheck::Geo::ClocksSynchronizationCheck,
      SystemCheck::App::GitUserDefaultSSHConfigCheck,
      SystemCheck::Geo::AuthorizedKeysCheck,
      SystemCheck::Geo::AuthorizedKeysFlagCheck,
      SystemCheck::App::HashedStorageEnabledCheck,
      SystemCheck::App::HashedStorageAllProjectsCheck
    ]
  end

  let(:secondary_checks) do
    [
      SystemCheck::Geo::GeoDatabaseConfiguredCheck,
      SystemCheck::Geo::DatabaseReplicationEnabledCheck,
      SystemCheck::Geo::DatabaseReplicationWorkingCheck,
      SystemCheck::Geo::HttpConnectionCheck,
      SystemCheck::Geo::SshPortCheck
    ] + common_checks
  end

  describe '.checks' do
    context 'primary node' do
      it 'secondary checks is skipped' do
        primary = create(:geo_node, :primary)
        stub_current_geo_node(primary)

        expect(described_class.checks).to eq(common_checks)
      end
    end

    context 'secondary node' do
      it 'secondary checks is called' do
        secondary = create(:geo_node)
        stub_current_geo_node(secondary)

        expect(described_class.checks).to eq(secondary_checks)
      end
    end

    context 'Geo disabled' do
      it 'secondary checks is skipped' do
        expect(described_class.checks).to eq(common_checks)
      end
    end

    context 'Geo is enabled but node is not identified' do
      it 'secondary checks is called' do
        create(:geo_node)

        expect(described_class.checks).to eq(secondary_checks)
      end
    end
  end
end
