# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Ingestion::Tasks::Base, feature_category: :dependency_management do
  let(:pipeline) { instance_double('Ci::Pipeline') }
  let(:occurrence_maps) { [instance_double('Sbom::Ingestion::OccurrenceMap')] }
  let(:implementation) { Class.new(described_class) }

  it 'raises error when execute is not implemented' do
    expect { implementation.execute(pipeline, occurrence_maps) }.to raise_error(NoMethodError)
  end
end
