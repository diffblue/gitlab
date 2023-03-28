# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ChangeVariableService, feature_category: :secrets_management do
  subject(:execute) { service.execute }

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let(:audit_service_spy) { class_spy(::Ci::AuditVariableChangeService, new: spy) }

  let(:service) do
    described_class.new(
      container: group, current_user: user,
      params: variable_params
    )
  end

  before do
    stub_const('::Ci::AuditVariableChangeService', audit_service_spy)
  end

  context 'when creating a variable' do
    let(:variable_params) { { variable_params: { key: 'new_variable', value: 'new_value' }, action: :create } }

    it 'calls AuditVariableChangeService with create' do
      execute

      expect(audit_service_spy).to have_received(:new).with(
        hash_including(
          container: group, current_user: user,
          params: hash_including(action: :create, variable: instance_of(::Ci::GroupVariable))
        )
      )
    end
  end

  context 'when updating a variable' do
    let(:variable) { create(:ci_group_variable) }
    let(:variable_params) { { variable_params: { key: variable.key, protected: 'true' }, action: :update } }

    before do
      group.variables << variable
    end

    it 'calls AuditVariableChangeService with update' do
      execute

      expect(audit_service_spy).to have_received(:new).with(
        hash_including(
          container: group, current_user: user,
          params: hash_including(action: :update, variable: instance_of(::Ci::GroupVariable))
        )
      )
    end
  end

  context 'when destroying a variable' do
    let(:variable) { create(:ci_group_variable, key: 'old_variable') }
    let(:variable_params) { { variable_params: { key: variable.key }, action: :destroy } }

    before do
      group.variables << variable
    end

    it 'calls AuditVariableChangeService with destroy' do
      execute

      expect(audit_service_spy).to have_received(:new).with(
        hash_including(
          container: group, current_user: user,
          params: hash_including(action: :destroy, variable: instance_of(::Ci::GroupVariable))
        )
      )
    end
  end
end
