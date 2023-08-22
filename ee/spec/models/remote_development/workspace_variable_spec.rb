# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::WorkspaceVariable, feature_category: :remote_development do
  let(:key) { 'key_1' }
  let(:value) { 'value_1' }
  let(:variable_type_env_var) { RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_ENV_VAR }
  let(:variable_type_file) { RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_FILE }
  let(:variable_type) { variable_type_file }
  let(:variable_type_values) do
    [
      variable_type_env_var,
      variable_type_file
    ]
  end

  let_it_be(:workspace) { create(:workspace, :without_workspace_variables) }

  subject do
    create(:workspace_variable, workspace: workspace, key: key, value: value, variable_type: variable_type)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:workspace) }

    it 'has correct associations from factory' do
      expect(subject.workspace).to eq(workspace)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_length_of(:key).is_at_most(255) }
    it { is_expected.to validate_presence_of(:variable_type) }
    it { is_expected.to validate_inclusion_of(:variable_type).in_array(variable_type_values) }
  end

  describe '#value' do
    it 'can be decrypted' do
      expect(subject.value).to eq(value)
    end
  end

  describe 'scopes' do
    describe 'with_variable_type_env_var' do
      let(:variable_type) { variable_type_env_var }

      it 'returns the record' do
        expect(described_class.with_variable_type_env_var).to eq([subject])
      end
    end

    describe 'with_variable_type_file' do
      let(:variable_type) { variable_type_file }

      it 'returns the record' do
        expect(described_class.with_variable_type_file).to eq([subject])
      end
    end
  end
end
