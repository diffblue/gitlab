# frozen_string_literal: true
require 'spec_helper'

RSpec.describe EE::GeoHelper, feature_category: :geo_replication do
  describe '.current_node_human_status' do
    where(:primary, :secondary, :result) do
      [
        [true, false, s_('Geo|primary')],
        [false, true, s_('Geo|secondary')],
        [false, false, s_('Geo|misconfigured')]
      ]
    end

    with_them do
      it 'returns correct results' do
        allow(::Gitlab::Geo).to receive(:primary?).and_return(primary)
        allow(::Gitlab::Geo).to receive(:secondary?).and_return(secondary)

        expect(described_class.current_node_human_status).to eq result
      end
    end
  end

  describe '#resync_all_button' do
    subject { helper.resync_all_button(count, 10001) }

    context 'when one project' do
      let!(:count) { 1 }

      it 'returns correct button' do
        is_expected.to have_button 'Resync all'
        is_expected.to include("Resync project")
      end
    end

    context 'when ten projects' do
      let!(:count) { 10 }

      it 'returns correct button' do
        is_expected.to include("Resync all 10 projects")
      end
    end

    context 'when 10,000+ projects' do
      let!(:count) { 10001 }

      it 'returns correct button' do
        is_expected.to include("Resync all 10,000+ projects")
      end
    end
  end

  describe '#reverify_all_button' do
    subject { helper.reverify_all_button(count, 10001) }

    context 'when one project' do
      let!(:count) { 1 }

      it 'returns correct button' do
        is_expected.to have_button 'Reverify all'
        is_expected.to include("Reverify project")
      end
    end

    context 'when ten projects' do
      let!(:count) { 10 }

      it 'returns correct button' do
        is_expected.to include("Reverify all 10 projects")
      end
    end

    context 'when 10,000+ projects' do
      let!(:count) { 10001 }

      it 'returns correct button' do
        is_expected.to include("Reverify all 10,000+ projects")
      end
    end
  end

  describe '#replicable_types' do
    subject(:names) { helper.replicable_types.map { |t| t[:name_plural] } }

    context 'with geo_project_wiki_repository_replication feature flag disabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: false)
      end

      it 'includes legacy types' do
        expected_names = %w(
          repositories
          wikis
          lfs_objects
          uploads
          job_artifacts
          design_repositories
        )

        expect(names).to include(*expected_names)
      end
    end

    context 'with geo_project_wiki_repository_replication feature flag enabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: true)
      end

      it 'includes legacy types' do
        expected_names = %w(
          repositories
          lfs_objects
          uploads
          job_artifacts
          design_repositories
        )

        expect(names).to include(*expected_names)
      end
    end

    it 'includes replicator types' do
      expected_names = helper.enabled_replicator_classes.map { |c| c.replicable_name_plural }

      expect(names).to include(*expected_names)
    end

    it 'includes replicator data types' do
      data_types = helper.replicable_types.map { |t| t[:data_type] }
      expected_data_types = helper.enabled_replicator_classes.map { |c| c.data_type }

      expect(data_types).to include(*expected_data_types)
    end

    it 'includes replicator data type titles' do
      data_type_titles = helper.replicable_types.map { |t| t[:data_type_title] }
      expected_data_type_titles = helper.enabled_replicator_classes.map { |c| c.data_type_title }

      expect(data_type_titles).to include(*expected_data_type_titles)
    end
  end

  describe '#geo_filter_nav_options' do
    let(:replicable_controller) { 'admin/geo/projects' }
    let(:replicable_name) { 'projects' }
    let(:expected_nav_options) do
      [
        { value: "", text: "All projects", href: "/admin/geo/replication/projects" },
        { value: "pending", text: "In progress", href: "/admin/geo/replication/projects?sync_status=pending" },
        { value: "failed", text: "Failed", href: "/admin/geo/replication/projects?sync_status=failed" },
        { value: "synced", text: "Synced", href: "/admin/geo/replication/projects?sync_status=synced" }
      ]
    end

    subject(:geo_filter_nav_options) { helper.geo_filter_nav_options(replicable_controller, replicable_name) }

    it 'returns correct urls' do
      expect(geo_filter_nav_options).to eq(expected_nav_options)
    end
  end

  describe '#geo_registry_status_text' do
    where(:synchronization_state, :pending_synchronization, :pending_verification, :result) do
      [
        [:never, false, false, 'Never'],
        [:failed, false, false, 'Failed'],
        [:pending, true, false, 'Pending synchronization'],
        [:pending, false, true, 'Pending verification'],
        [:pending, false, false, 'Unknown'],
        [:synced, false, false, 'Synced'],
        [:fake, false, false, 'Unknown']
      ]
    end

    with_them do
      let(:registry) do
        Struct.new(
          :synchronization_state,
          :pending_synchronization?,
          :pending_verification?
        ).new(synchronization_state, pending_synchronization, pending_verification)
      end

      it 'returns the correct result' do
        expect(helper.geo_registry_status_text(registry)).to eq(result)
      end
    end
  end
end
