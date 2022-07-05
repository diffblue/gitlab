# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DeployTokens::CreateService do
  let_it_be(:entity) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:deploy_token_params) { attributes_for(:deploy_token) }

  describe '#execute' do
    subject { described_class.new(entity, user, deploy_token_params).execute }

    context 'when the deploy token is valid' do
      it 'creates an audit event' do
        expect { subject }.to change { AuditEvent.count }.by(1)

        expected_message = <<~MESSAGE.squish
          Created group deploy token with name: #{subject[:deploy_token].name}
          with token_id: #{subject[:deploy_token].id} with scopes: #{subject[:deploy_token].scopes}.
        MESSAGE

        expect(AuditEvent.last.details[:custom_message]).to eq(expected_message)
      end

      context 'when group is a sub-group' do
        let_it_be(:parent_group) { create :group }
        let_it_be(:group) { create :group, parent: parent_group }

        subject { described_class.new(group, user, deploy_token_params).execute }

        before do
          group.add_owner(user)
        end

        include_examples 'sends streaming audit event'
      end
    end

    context 'when the deploy token is invalid' do
      let(:deploy_token_params) { attributes_for(:deploy_token, read_repository: false, read_registry: false, write_registry: false) }

      it 'creates an audit event' do
        expect { subject }.to change { AuditEvent.count }.by(1)

        expected_message = "Attempted to create group deploy token but failed with message: Scopes can't be blank"

        expect(AuditEvent.last.details[:custom_message]).to eq(expected_message)
      end
    end
  end
end
