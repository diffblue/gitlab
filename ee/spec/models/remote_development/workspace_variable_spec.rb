# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::WorkspaceVariable, feature_category: :remote_development do
  let(:variable_type_values) { { env_var: 0, file: 1 } }
  let(:key) { 'key_1' }
  let(:value) { 'value_1' }
  let_it_be(:workspace) do
    create(:workspace)
  end

  subject do
    create(:workspace_variable, workspace: workspace, key: key, value: value)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:workspace) }

    it 'has correct associations from factory' do
      expect(subject.workspace).to eq(workspace)
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:variable_type).with_values(variable_type_values).with_prefix(:variable_type) }

    it_behaves_like 'having unique enum values'
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_length_of(:key).is_at_most(255) }
    it { is_expected.to validate_presence_of(:variable_type) }
  end

  describe '#value' do
    it 'can be decrypted' do
      expect(subject.value).to eq(value)
    end
  end
end
