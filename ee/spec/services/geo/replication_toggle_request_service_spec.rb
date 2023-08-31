# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ReplicationToggleRequestService, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ApiHelpers

  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:primary) { create(:geo_node, :primary) }

  subject { described_class.new(enabled: false) }

  before do
    stub_current_geo_node(secondary)
  end

  it_behaves_like 'a geo RequestService'

  it 'expires the geo cache on success' do
    response = double(
      success?: true,
      code: 200,
      parsed_response: { 'message' => 'Test' }
    )
    allow(Gitlab::HTTP).to receive(:perform_request).and_return(response)
    expect(Gitlab::Geo).to receive(:expire_cache!)

    expect(subject.execute).to be_truthy
  end

  it 'does not expire the geo cache on failure' do
    response = double(
      success?: false,
      code: 401,
      message: 'Unauthorized',
      parsed_response: { 'message' => 'Test' }
    )

    allow(Gitlab::HTTP).to receive(:perform_request).and_return(response)
    expect(Gitlab::Geo).not_to receive(:expire_cache!)

    expect(subject.execute).to be_falsey
  end
end
