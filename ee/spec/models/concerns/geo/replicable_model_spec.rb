# frozen_string_literal: true

require 'spec_helper'

# Also see ee/spec/support/shared_examples/models/concerns/replicable_model_shared_examples.rb:
#
# - Place tests here in replicable_model_spec.rb if you want to run them once,
#   against a DummyModel.
# - Place tests in replicable_model_shared_examples.rb if you want them to be
#   run against every real Model.
RSpec.describe Geo::ReplicableModel, feature_category: :geo_replication do
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

  describe '#geo_create_event!' do
    context 'when the replicator raises an error' do
      let(:error) { StandardError.new("testing error") }

      before do
        expect_next_instance_of(Geo::DummyReplicator) do |instance|
          expect(instance).to receive(:handle_after_create_commit).and_raise(error)
        end
      end

      it 'saves the model' do
        expect { subject.save! }.to change { DummyModel.count }.by(1)
      end
    end
  end

  describe 'after_destroy hook' do
    context 'when the replicator raises an error' do
      let(:error) { StandardError.new("testing error") }

      before do
        expect_next_instance_of(Geo::DummyReplicator) do |instance|
          expect(instance).to receive(:handle_after_destroy).and_raise(error)
        end
      end

      it 'destroys the model' do
        subject.save!

        expect { subject.destroy! }.to change { DummyModel.count }.by(-1)
      end
    end
  end

  describe '.verifiables' do
    context 'when the model can be filtered by locally stored files' do
      it 'filters by locally stored files' do
        allow(DummyModel).to receive(:respond_to?).with(:all).and_call_original
        allow(DummyModel).to receive(:respond_to?).with(:with_files_stored_locally).and_return(true)

        expect(DummyModel).to receive(:with_files_stored_locally)

        DummyModel.verifiables
      end
    end

    context 'when the model cannot be filtered by locally stored files' do
      it 'does not filter by locally stored files' do
        allow(DummyModel).to receive(:respond_to?).with(:all).and_call_original
        allow(DummyModel).to receive(:respond_to?).with(:with_files_stored_locally).and_return(false)

        expect(DummyModel).not_to receive(:with_files_stored_locally)

        DummyModel.verifiables
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
