# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::HasReplicator, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let_it_be(:primary_node) { create(:geo_node, :primary) }
  let_it_be(:secondary_node) { create(:geo_node) }

  before_all do
    create_dummy_model_table
  end

  after(:all) do
    drop_dummy_model_table
  end

  before do
    stub_dummy_replicator_class
    stub_dummy_model_class
  end

  subject { DummyModel.new }

  describe '#replicator' do
    it 'adds replicator method to the model' do
      expect(subject).to respond_to(:replicator)
    end

    it 'instantiates a replicator into the model' do
      expect(subject.replicator).to be_a(Geo::DummyReplicator)
    end

    context 'when replicator is not defined in inheriting class' do
      before do
        stub_const('DummyModel', Class.new(ApplicationRecord))

        DummyModel.class_eval do
          include ::Geo::HasReplicator
          self.table_name = "_test_dummy_models"
        end
      end

      it 'raises NotImplementedError' do
        expect { DummyModel.new.replicator }.to raise_error(NotImplementedError)
      end
    end
  end
end
