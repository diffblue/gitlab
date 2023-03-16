# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::AutoRollbackWorker, feature_category: :continuous_delivery do
  let_it_be(:environment) { create(:environment) }

  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(environment_id) }

    let(:environment_id) { environment.id }

    it 'executes the rollback service' do
      expect_next_instance_of(Deployments::AutoRollbackService, environment.project, nil) do |service|
        expect(service).to receive(:execute).with(environment)
      end

      subject
    end

    context 'when an environment does not exist' do
      let(:environment_id) { non_existing_record_id }

      it 'does not execute the rollback service' do
        expect(Deployments::AutoRollbackService).not_to receive(:new)

        subject
      end
    end
  end
end
