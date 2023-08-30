# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::BulkMarkVerificationPendingBatchWorker, :geo, feature_category: :geo_replication do
  include EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }

  subject(:worker) { described_class.new }

  before do
    stub_current_geo_node(secondary)
  end

  include_context 'with geo registries shared context'

  with_them do
    it_behaves_like 'a Geo bulk mark update batch worker' do
      let(:service) { ::Geo::BulkMarkVerificationPendingService }
    end

    include_examples 'an idempotent worker' do
      let(:job_args) { [registry_class.name] }
    end
  end
end
