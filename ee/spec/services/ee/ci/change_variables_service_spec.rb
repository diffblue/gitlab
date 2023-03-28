# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ChangeVariablesService, feature_category: :secrets_management do
  subject(:execute) { service.execute }

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let(:audit_service_spy) { class_spy(Ci::AuditVariableChangeService, new: spy) }

  let(:service) do
    described_class.new(
      container: group, current_user: user,
      params: variable_params
    )
  end

  before do
    stub_const('Ci::AuditVariableChangeService', audit_service_spy)
  end

  context 'when creating a variable' do
    let(:variable_params) { { variables_attributes: [{ key: 'new_variable', value: 'new_value' }] } }

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
    let(:variable_params) { { variables_attributes: [{ id: variable.id }.merge(variable_changes)] } }

    before do
      group.variables << variable
    end

    context 'when update succeeds' do
      let(:variable_changes) { { protected: 'true' } }

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

    context 'when update fails' do
      let(:variable_changes) { { value: 'shrt', masked: 'true' } }

      it 'does not call AuditVariableChangeService' do
        execute

        expect(audit_service_spy).not_to have_received(:new)
      end
    end
  end

  context 'when destroying a variable' do
    let(:variable) { create(:ci_group_variable, key: 'old_variable') }
    let(:variable_params) { { variables_attributes: [{ id: variable.id, key: variable.key, _destroy: 'true' }] } }

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

  context 'when making multiple changes' do
    let(:update_variable) { create(:ci_group_variable) }
    let(:delete_variable) { create(:ci_group_variable, key: 'old_variable') }

    let(:variable_params) do
      {
        variables_attributes: [
          { key: 'new_variable', value: 'new_value' },
          { id: update_variable.id, protected: 'true' },
          { id: delete_variable.id, key: delete_variable.key, _destroy: 'true' }
        ]
      }
    end

    before do
      group.variables << update_variable
      group.variables << delete_variable
    end

    it 'calls AuditVariableChangeService with create' do
      execute

      expect(audit_service_spy).to have_received(:new).with(
        hash_including(
          container: group, current_user: user,
          params: hash_including(action: :create, variable: instance_of(::Ci::GroupVariable))
        )
      )
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
