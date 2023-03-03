# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::EventService, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  let(:model_record) { create(:package_file, :npm) }

  subject { described_class.new('package_file', 'created', { 'model_record_id' => model_record.id }) }

  describe '#execute' do
    before do
      resource_url = primary.geo_retrieve_url(replicable_name: 'package_file', replicable_id: model_record.id.to_s)
      content = model_record.file.open
      File.unlink(model_record.file.path)
      stub_request(:get, resource_url).to_return(status: 200, body: content)
      stub_current_geo_node(secondary)
    end

    it 'executes the consume part of the replication' do
      subject.execute

      expect(model_record.file.exists?).to be_truthy
    end
  end
end
