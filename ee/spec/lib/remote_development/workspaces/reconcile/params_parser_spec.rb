# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::Reconcile::ParamsParser, :freeze_time, feature_category: :remote_development do
  let(:update_type) { 'full' }
  let(:workspace_error_details) do
    {
      "error_type" => "applier",
      "error_message" => "something has gone wrong"
    }
  end

  let(:workspace_agent_infos) do
    [{
      "termination_progress" => "Terminated",
      "error_details" => workspace_error_details
    }]
  end

  let(:params) do
    {
      'update_type' => update_type,
      'workspace_agent_infos' => workspace_agent_infos
    }
  end

  subject { described_class.new.parse(params: params) }

  context 'when the params are valid' do
    shared_examples "returns parsed params without error" do
      it 'returns the parsed params' do
        expect(subject).to eq([{
          workspace_agent_infos: workspace_agent_infos,
          update_type: update_type
        }, nil])
      end
    end

    context "when all fields are populated with valid values" do
      it_behaves_like "returns parsed params without error"
    end

    context "when error_details is missing" do
      let(:workspace_error_details) { nil }

      it_behaves_like "returns parsed params without error"
    end
  end

  context 'when the params are invalid' do
    shared_examples 'returns nil params and an error' do
      it 'returns nil params and an error' do
        params, error = subject
        expect(params).to be_nil
        expect(error.message).to eq(expected_error_message)
        expect(error.reason).to eq(expected_error_reason)
      end
    end

    let(:expected_error_reason) { :unprocessable_entity }

    context 'when workspace_agent_info is missing' do
      let(:expected_error_message) { 'root is missing required keys: workspace_agent_infos' }
      let(:params) do
        {
          'update_type' => update_type
        }
      end

      it_behaves_like 'returns nil params and an error'
    end

    context 'for update_type' do
      context 'when missing' do
        let(:expected_error_message) { 'root is missing required keys: update_type' }
        let(:params) do
          {
            'workspace_agent_infos' => workspace_agent_infos
          }
        end

        it_behaves_like 'returns nil params and an error'
      end

      context 'when invalid' do
        let(:expected_error_message) { %(property '/update_type' is not one of: ["partial", "full"]) }
        let(:params) do
          {
            'update_type' => 'invalid_update_type',
            'workspace_agent_infos' => workspace_agent_infos
          }
        end

        it_behaves_like 'returns nil params and an error'
      end
    end

    context 'for error_details' do
      context 'when error_type is missing' do
        let(:expected_error_message) do
          "property '/workspace_agent_infos/0/error_details' is missing required keys: error_type"
        end

        let(:workspace_error_details) do
          {
            "error_message" => "something has gone wrong"
          }
        end

        it_behaves_like 'returns nil params and an error'
      end

      context 'when error_type has an invalid value' do
        let(:expected_error_message) do
          %(property '/workspace_agent_infos/0/error_details/error_type' is not one of: ["applier"])
        end

        let(:workspace_error_details) do
          {
            "error_type" => "unknown",
            "error_message" => "something has gone wrong"
          }
        end

        it_behaves_like 'returns nil params and an error'
      end
    end

    context 'for termination_progress' do
      context 'when termination_progress is invalid' do
        let(:workspace_agent_infos) do
          [{
            "termination_progress" => "invalidValue"
          }]
        end

        let(:expected_error_message) do
          %(property '/workspace_agent_infos/0/termination_progress' is not one of: ["Terminating", "Terminated"])
        end

        it_behaves_like 'returns nil params and an error'
      end
    end
  end
end
