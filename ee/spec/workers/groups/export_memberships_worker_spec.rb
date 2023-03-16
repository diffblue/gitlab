# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ExportMembershipsWorker, feature_category: :compliance_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    stub_licensed_features(export_user_permissions: true)
    group.add_owner(user)
  end

  subject(:worker) { described_class.new }

  it 'enqueues an email' do
    expect(Notify).to receive(:memberships_export_email).once.and_call_original

    worker.perform(group.id, user.id)
  end
end
