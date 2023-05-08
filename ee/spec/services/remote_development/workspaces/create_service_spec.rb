# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::CreateService, feature_category: :remote_development do
  describe '#execute' do
    let(:user) { project.owner }
    let(:group) { instance_double(Group) }
    let(:params) { { project: project } }
    let_it_be(:project) { create :project }
    let(:process_args) { { params: params } }

    subject do
      described_class.new(current_user: user).execute(params: params)
    end

    context 'when create is successful' do
      let(:payload) { instance_double(Hash) }

      it 'returns a success ServiceResponse' do
        allow_next_instance_of(RemoteDevelopment::Workspaces::Create::CreateProcessor) do |processor|
          expect(processor).to receive(:process).with(params: hash_including(:project)).and_return([payload, nil])
        end
        expect(subject).to be_a(ServiceResponse)
        expect(subject.payload).to eq(payload)
        expect(subject.message).to be_nil
      end
    end

    context 'when user is not authorized' do
      let(:user) { build_stubbed(:user) }

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

      it 'returns an error ServiceResponse' do
        allow_next_instance_of(RemoteDevelopment::Workspaces::Create::CreateProcessor) do |processor|
          expect(processor).to receive(:process).with(params: hash_including(:project)).and_return([nil, error])
        end
        expect(subject).to be_a(ServiceResponse)
        expect(subject.payload).to eq({}) # NOTE: A nil payload gets turned into an empty hash
        expect(subject.message).to eq(message)
        expect(subject.reason).to eq(reason)
      end
    end
  end
end
