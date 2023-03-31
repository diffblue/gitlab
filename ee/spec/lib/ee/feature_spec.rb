# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Feature, stub_feature_flags: false, query_analyzers: false do
  include EE::GeoHelpers

  describe '.register_feature_groups' do
    before do
      Flipper.unregister_groups
      described_class.register_feature_groups
    end

    it 'registers expected groups' do
      expect(Flipper.groups).to include(an_object_having_attributes(name: :gitlab_team_members))
    end
  end

  describe '.enabled?' do
    before do
      described_class.reset
      skip_feature_flags_yaml_validation
      allow(described_class).to receive(:log_feature_flag_states?).and_return(false)

      stub_feature_flag_definition(:disabled_feature_flag)
      stub_feature_flag_definition(:enabled_feature_flag, default_enabled: true)
    end

    context 'with gitlab_team_members feature group' do
      let(:actor) { build_stubbed(:user) }

      before do
        Flipper.unregister_groups
        described_class.register_feature_groups
        described_class.enable(:enabled_feature_flag, :gitlab_team_members)
      end

      it 'delegates check to Gitlab::Com.gitlab_com_group_member?' do
        expect(Gitlab::Com).to receive(:gitlab_com_group_member?).with(actor)

        described_class.enabled?(:enabled_feature_flag, actor)
      end
    end
  end

  describe '.enable' do
    context 'when running on a Geo primary node' do
      before do
        stub_primary_node
      end

      it 'does not create a Geo::CacheInvalidationEvent if there are no Geo secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { described_class.enable(:foo) }.not_to change(Geo::CacheInvalidationEvent, :count)
      end

      it 'creates a Geo::CacheInvalidationEvent' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [double] }

        expect { described_class.enable(:foo) }.to change(Geo::CacheInvalidationEvent, :count).by(1)
      end
    end
  end

  describe '.disable' do
    context 'when running on a Geo primary node' do
      before do
        stub_primary_node
      end

      it 'does not create a Geo::CacheInvalidationEvent if there are no Geo secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { described_class.disable(:foo) }.not_to change(Geo::CacheInvalidationEvent, :count)
      end

      it 'creates a Geo::CacheInvalidationEvent' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [double] }

        expect { described_class.disable(:foo) }.to change(Geo::CacheInvalidationEvent, :count).by(1)
      end
    end
  end

  describe Feature::Target do
    describe '#targets' do
      context 'when repository target works with group wiki' do
        let_it_be(:group) { create(:group) }

        subject do
          described_class.new(repository: group.wiki.repository.full_path)
        end

        it 'returns all found targets' do
          expect(subject.targets).to be_an(Array)
          expect(subject.targets).to eq([group.wiki.repository])
        end
      end
    end
  end
end
