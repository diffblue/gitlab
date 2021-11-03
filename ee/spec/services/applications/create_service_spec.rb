# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Applications::CreateService do
  include TestRequestHelpers

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let(:params) { attributes_for(:application) }

  subject { described_class.new(user, params) }

  describe '#audit_event_service' do
    using RSpec::Parameterized::TableSyntax

    where(:case_name, :owner, :entity_type) do
      'instance application' | nil   | 'User'
      'group application'    | group | 'Group'
      'user application'     | user  | 'User'
    end

    with_them do
      before do
        stub_licensed_features(extended_audit_events: true)
        params[:owner] = owner
      end

      it 'creates AuditEvent with correct entity type' do
        expect { subject.execute(test_request) }.to change(AuditEvent, :count).by(1)
        expect(AuditEvent.last.entity_type).to eq(entity_type)
      end
    end
  end
end
