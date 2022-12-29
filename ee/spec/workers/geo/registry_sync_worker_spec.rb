# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RegistrySyncWorker, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  it_behaves_like 'a framework registry sync worker', :geo_package_file_registry, :files_max_capacity do
    before do
      result_object = double(
        :result,
        success: true,
        bytes_downloaded: 100,
        primary_missing_file: false,
        reason: '',
        extra_details: {}
      )

      allow_any_instance_of(::Gitlab::Geo::Replication::BlobDownloader).to receive(:execute).and_return(result_object)
    end
  end

  describe '#max_capacity' do
    let(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(secondary)
      secondary.update!(container_repositories_max_capacity: 3, files_max_capacity: 6, repos_max_capacity: 7)
    end

    it 'returns only files_max_capacity based capacity' do
      expect(subject.send(:max_capacity)).to eq(6)
    end
  end
end
