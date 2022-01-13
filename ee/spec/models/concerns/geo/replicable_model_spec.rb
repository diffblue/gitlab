# frozen_string_literal: true

require 'spec_helper'

# Also see ee/spec/support/shared_examples/models/concerns/replicable_model_shared_examples.rb:
#
# - Place tests here in replicable_model_spec.rb if you want to run them once,
#   against a DummyModel.
# - Place tests in replicable_model_shared_examples.rb if you want them to be
#   run against every real Model.
RSpec.describe Geo::ReplicableModel do
  include ::EE::GeoHelpers

  let_it_be(:primary_node) { create(:geo_node, :primary) }
  let_it_be(:secondary_node) { create(:geo_node) }

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

  it_behaves_like 'a replicable model' do
    let(:model_record) { subject }
    let(:replicator_class) { Geo::DummyReplicator }
  end

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
        DummyModel.class_eval { include ::Geo::ReplicableModel }
      end

      it 'raises NotImplementedError' do
        expect { DummyModel.new.replicator }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '#in_replicables_for_current_secondary?' do
    it 'reuses replicables_for_current_secondary' do
      expect(DummyModel).to receive(:replicables_for_current_secondary).once.with(subject).and_call_original

      subject.in_replicables_for_current_secondary?
    end
  end
end
