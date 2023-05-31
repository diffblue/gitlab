# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database do
  include ::EE::GeoHelpers

  describe '.db_config_names' do
    using RSpec::Parameterized::TableSyntax

    where(:configs_for, :gitlab_schema, :expected) do
      %i[main geo] | nil | %i[main geo]
      %i[main geo] | :gitlab_internal | %i[main geo]
      %i[main geo] | :gitlab_shared | %i[main] # geo does not have `gitlab_shared`
      %i[main geo] | :gitlab_geo | %i[geo]
    end

    with_them do
      before do
        skip_if_multiple_databases_not_setup(:geo)

        hash_configs = configs_for.map do |x|
          instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, name: x)
        end
        allow(::ActiveRecord::Base).to receive(:configurations).and_return(
          instance_double(ActiveRecord::DatabaseConfigurations, configs_for: hash_configs)
        )
      end

      it do
        expect(described_class.db_config_names(with_schema: gitlab_schema))
          .to eq(expected)
      end
    end
  end

  describe '.read_only?' do
    context 'with Geo enabled' do
      before do
        allow(Gitlab::Geo).to receive(:enabled?) { true }
        allow(Gitlab::Geo).to receive(:current_node) { geo_node }
      end

      context 'is Geo secondary node' do
        let(:geo_node) { create(:geo_node) }

        it 'returns true' do
          expect(described_class.read_only?).to be_truthy
        end
      end

      context 'is Geo primary node' do
        let(:geo_node) { create(:geo_node, :primary) }

        it 'returns false when is Geo primary node' do
          expect(described_class.read_only?).to be_falsey
        end
      end
    end

    context 'with Geo disabled' do
      it 'returns false' do
        expect(described_class.read_only?).to be_falsey
      end
    end

    context 'in maintenance mode' do
      before do
        stub_maintenance_mode_setting(true)
      end

      it 'returns true' do
        expect(described_class.read_only?).to be_truthy
      end
    end
  end
end
