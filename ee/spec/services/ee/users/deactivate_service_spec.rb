# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DeactivateService, feature_category: :user_management do
  let_it_be(:current_user) { create(:admin) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute' do
    let!(:user) { create(:user) }

    subject(:operation) { service.execute(user) }

    context 'for audit events', :enable_admin_mode do
      include_examples 'audit event logging' do
        let(:operation) { service.execute(user) }

        let(:fail_condition!) do
          allow(user).to receive(:deactivate).and_return(false)
        end

        let(:attributes) do
          {
            author_id: current_user.id,
            entity_id: user.id,
            entity_type: 'User',
            details: {
              author_class: 'User',
              author_name: current_user.name,
              custom_message: 'Deactivated user',
              target_details: user.username,
              target_id: user.id,
              target_type: 'User'
            }
          }
        end
      end
    end
  end
end
