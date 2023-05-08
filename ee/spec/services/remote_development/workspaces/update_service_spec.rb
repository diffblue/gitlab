# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::UpdateService, feature_category: :remote_development do
  let(:workspace) { build_stubbed(:workspace) }
  let(:user) { instance_double(User, can?: true) }
  let(:params) { instance_double(Hash) }
  let(:process_args) { { workspace: workspace, params: params } }

  subject do
    described_class.new(current_user: user).execute(workspace: workspace, params: params)
  end

  context 'when create is successful' do
    let(:payload) { instance_double(Hash) }

    it 'returns a success ServiceResponse' do
      allow_next_instance_of(RemoteDevelopment::Workspaces::Update::UpdateProcessor) do |processor|
        expect(processor).to receive(:process).with(process_args).and_return([payload, nil])
      end
      expect(subject).to be_a(ServiceResponse)
      expect(subject.payload).to eq(payload)
      expect(subject.message).to be_nil
    end
  end

  context 'when user is not authorized' do
    let(:user) { instance_double(User, can?: false) }

    it 'returns an error ServiceResponse' do
      # noinspection RubyResolve
      expect(subject).to be_error
      expect(subject.payload).to eq({})
      expect(subject.message).to eq('Unauthorized')
      expect(subject.reason).to eq(:unauthorized)
    end
  end

  context 'when create fails' do
    let(:message) { 'error message' }
    let(:reason) { :bad_request }
    let(:error) { RemoteDevelopment::Error.new(message: message, reason: reason) }

    context 'when authorized' do
      it 'returns an error ServiceResponse' do
        allow_next_instance_of(RemoteDevelopment::Workspaces::Update::UpdateProcessor) do |processor|
          expect(processor).to receive(:process).with(process_args).and_return([nil, error])
        end
        expect(subject).to be_a(ServiceResponse)
        expect(subject.payload).to eq({}) # NOTE: A nil payload gets turned into an empty hash
        expect(subject.message).to eq(message)
        expect(subject.reason).to eq(reason)
      end
    end
  end
end
