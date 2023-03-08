# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallRotations::RemoveParticipantsService, feature_category: :incident_management do
  let!(:user) { instance_double(User) }
  let!(:rotation) { instance_double(IncidentManagement::OncallRotation) }
  let!(:rotation_2) { instance_double(IncidentManagement::OncallRotation) }

  let(:service) { described_class.new([rotation, rotation_2], user) }

  subject(:execute) { service.execute }

  before do
    stub_licensed_features(oncall_schedules: true)
  end

  it 'calls the RemoveParticipantService for each rotation' do
    remove_service = instance_spy(IncidentManagement::OncallRotations::RemoveParticipantService)

    expect(IncidentManagement::OncallRotations::RemoveParticipantService)
      .to receive(:new)
      .with(rotation, user, true)
      .and_return(remove_service)

    expect(IncidentManagement::OncallRotations::RemoveParticipantService)
      .to receive(:new)
      .with(rotation_2, user, true)
      .and_return(remove_service)

    expect(remove_service).to receive(:execute).twice

    execute
  end
end
