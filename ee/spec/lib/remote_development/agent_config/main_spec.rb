# frozen_string_literal: true

require_relative '../fast_spec_helper'

RSpec.describe RemoteDevelopment::AgentConfig::Main, feature_category: :remote_development do
  include RemoteDevelopment::RailwayOrientedProgrammingHelpers

  let(:value) { {} }
  let(:error_details) { 'some error details' }
  let(:err_message_context) { { details: error_details } }

  # Classes

  let(:license_checker_class) { RemoteDevelopment::AgentConfig::LicenseChecker }
  let(:updater_class) { RemoteDevelopment::AgentConfig::Updater }

  # Methods

  let(:license_checker_method) { license_checker_class.singleton_method(:check_license) }
  let(:updater_method) { updater_class.singleton_method(:update) }

  # Subject

  subject(:response) { described_class.main(value) }

  before do
    allow(license_checker_class).to receive(:method) { license_checker_method }
    allow(updater_class).to receive(:method) { updater_method }
  end

  context 'when the LicenseChecker returns an err Result' do
    let(:err_message_context) { {} }

    before do
      stub_methods_to_return_err_result(
        method: license_checker_method,
        message_class: RemoteDevelopment::Messages::LicenseCheckFailed
      )
    end

    it 'returns a forbidden error response' do
      expect(response).to eq(
        { status: :error, message: "License check failed", reason: :forbidden }
      )
    end
  end

  context 'when the Updater returns an err Result' do
    let(:errors) { ActiveModel::Errors.new(:base) }
    let(:err_message_context) { { errors: errors } }

    before do
      stub_methods_to_return_ok_result(
        license_checker_method
      )
      stub_methods_to_return_err_result(
        method: updater_method,
        message_class: RemoteDevelopment::Messages::AgentConfigUpdateFailed
      )

      errors.add(:base, 'err1')
      errors.add(:base, 'err2')
    end

    it 'returns a agent_config update failed error response' do
      expect(response).to eq({
        status: :error,
        message: "Agent config update failed: err1, err2",
        reason: :bad_request
      })
    end
  end

  context 'when the Updater returns an AgentConfigUpdateSkippedBecauseNoConfigFileEntryFound Result' do
    let(:skip_updater_context) { { skipped_reason: :some_skipped_reason } }

    before do
      stub_methods_to_return_ok_result(
        license_checker_method
      )
      allow(updater_method).to receive(:call).with(value) do
        Result.ok(
          RemoteDevelopment::Messages::AgentConfigUpdateSkippedBecauseNoConfigFileEntryFound.new(skip_updater_context)
        )
      end
    end

    it 'returns a agent_config update success response with the skipped payload' do
      expect(response).to eq({
        status: :success,
        payload: skip_updater_context
      })
    end
  end

  context 'when the Updater returns an AgentConfigUpdateSuccessful Result' do
    let(:agent_config) { instance_double("RemoteDevelopment::RemoteDevelopmentAgentConfig") }

    before do
      stub_methods_to_return_ok_result(
        license_checker_method
      )
      allow(updater_method).to receive(:call).with(value) do
        Result.ok(RemoteDevelopment::Messages::AgentConfigUpdateSuccessful.new(
          { remote_development_agent_config: agent_config }
        ))
      end
    end

    it 'returns a agent_config update success response with the agent_config as the payload' do
      expect(response).to eq({
        status: :success,
        payload: { remote_development_agent_config: agent_config }
      })
    end
  end

  context 'when an invalid Result is returned' do
    # noinspection RailsParamDefResolve
    let(:agent_config) { build_stubbed(:agent_config) }

    before do
      stub_methods_to_return_ok_result(
        license_checker_method
      )
      allow(updater_method).to receive(:call).with(value) do
        Result.err(RemoteDevelopment::Messages::AgentConfigUpdateSuccessful.new)
      end
    end

    it 'raises an UnmatchedResultError' do
      expect { response }.to raise_error(RemoteDevelopment::UnmatchedResultError)
    end
  end
end
