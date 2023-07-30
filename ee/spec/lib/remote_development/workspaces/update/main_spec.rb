# frozen_string_literal: true

require_relative '../../fast_spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Update::Main, feature_category: :remote_development do
  include RemoteDevelopment::RailwayOrientedProgrammingHelpers

  let(:value) { {} }
  let(:error_details) { 'some error details' }
  let(:err_message_context) { { details: error_details } }

  # Classes

  let(:authorizer_class) { RemoteDevelopment::Workspaces::Update::Authorizer }
  let(:updater_class) { RemoteDevelopment::Workspaces::Update::Updater }

  # Methods

  let(:authorizer_method) { authorizer_class.singleton_method(:authorize) }
  let(:updater_method) { updater_class.singleton_method(:update) }

  # Subject

  subject(:response) { described_class.main(value) }

  before do
    allow(authorizer_class).to receive(:method) { authorizer_method }
    allow(updater_class).to receive(:method) { updater_method }
  end

  context 'when the Authorizer returns an err Result' do
    let(:err_message_context) { {} }

    before do
      stub_methods_to_return_err_result(
        method: authorizer_method,
        message_class: RemoteDevelopment::Messages::Unauthorized
      )
    end

    it 'returns an unauthorized error response' do
      expect(response).to eq({ status: :error, message: 'Unauthorized', reason: :unauthorized })
    end
  end

  context 'when the Updater returns an err Result' do
    let(:errors) { ActiveModel::Errors.new(:base) }
    let(:err_message_context) { { errors: errors } }

    before do
      stub_methods_to_return_ok_result(
        authorizer_method
      )
      stub_methods_to_return_err_result(
        method: updater_method,
        message_class: RemoteDevelopment::Messages::WorkspaceUpdateFailed
      )

      errors.add(:base, 'err1')
      errors.add(:base, 'err2')
    end

    it 'returns a workspace update failed error response' do
      expect(response).to eq({
        status: :error,
        message: "Workspace update failed: err1, err2",
        reason: :bad_request
      })
    end
  end

  context 'when the Updater returns an ok Result' do
    let(:workspace) { instance_double("RemoteDevelopment::Workspace") }

    before do
      stub_methods_to_return_ok_result(
        authorizer_method
      )
      allow(updater_method).to receive(:call).with(value) do
        Result.ok(RemoteDevelopment::Messages::WorkspaceUpdateSuccessful.new({ workspace: workspace }))
      end
    end

    it 'returns a workspace update success response with the workspace as the payload' do
      expect(response).to eq({
        status: :success,
        payload: { workspace: workspace }
      })
    end
  end

  context 'when an invalid Result is returned' do
    let(:workspace) { build_stubbed(:workspace) }

    before do
      stub_methods_to_return_ok_result(
        authorizer_method
      )
      allow(updater_method).to receive(:call).with(value) do
        # Note that this is not pattern matched, because there's no match for a `Result.err` with this message.
        Result.err(RemoteDevelopment::Messages::WorkspaceUpdateSuccessful.new)
      end
    end

    it 'raises an UnmatchedResultError' do
      expect { response }.to raise_error(RemoteDevelopment::UnmatchedResultError)
    end
  end
end
