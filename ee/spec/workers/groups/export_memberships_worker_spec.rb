# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ExportMembershipsWorker do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    stub_licensed_features(export_user_permissions: true)
    stub_feature_flags(ff_group_membership_export: true)
    group.add_owner(user)
  end

  subject(:worker) { described_class.new }

  it 'enqueues an email' do
    expect(Notify).to receive(:memberships_export_email).once.and_call_original

    worker.perform(group.id, user.id)
  end

  context 'when there is a Module::DelegationError' do
    before do
      allow_next_instance_of(Groups::Memberships::ExportService) do |service|
        allow(service).to receive(:execute).and_raise(Module::DelegationError)
      end
    end

    it 'rescues the exception' do
      expect(Notify).not_to receive(:memberships_export_email)
      expect(Raven).to receive(:capture_exception)
      worker.perform(group.id, user.id)
    end
  end
end
