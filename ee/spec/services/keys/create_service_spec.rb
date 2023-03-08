# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Keys::CreateService, feature_category: :source_code_management do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  let(:params) { attributes_for(:key).merge(user: user) }

  subject { described_class.new(admin, params) }

  it 'creates' do
    stub_licensed_features(extended_audit_events: true)

    expect { subject.execute }.to change { AuditEvent.count }.by(1)

    event = AuditEvent.last

    expect(event.author_name).to eq(admin.name)
    expect(event.entity_id).to eq(user.id)
  end
end
