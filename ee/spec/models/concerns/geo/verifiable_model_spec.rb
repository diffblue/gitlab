# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::VerifiableModel, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  context 'when separate table is used for verification state' do
    before(:all) do
      create_dummy_model_with_separate_state_table
    end

    after(:all) do
      drop_dummy_model_with_separate_state_table
    end

    before do
      stub_dummy_replicator_class(model_class: 'TestDummyModelWithSeparateState')
      stub_dummy_model_with_separate_state_class
    end

    subject { TestDummyModelWithSeparateState.new }

    describe '.verification_state_model_key' do
      it 'returns the primary key of the state model' do
        expect(subject.class.verification_state_model_key).to eq(TestDummyModelState.primary_key)
      end
    end
  end

  context 'when separate table is not used for verification state' do
    before(:all) do
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

    describe '.verification_state_object' do
      it 'returns self' do
        expect(subject.verification_state_object.id).to eq(subject.id)
      end
    end

    describe '.verification_state_model_key' do
      it 'returns the primary key of the model' do
        expect(subject.class.verification_state_model_key).to eq(DummyModel.primary_key)
      end
    end
  end
end
