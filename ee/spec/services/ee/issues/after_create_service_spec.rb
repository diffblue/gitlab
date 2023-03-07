# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::AfterCreateService, feature_category: :team_planning do
  include AfterNextHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project, author: current_user) }

  subject(:after_create_service) { described_class.new(container: project, current_user: current_user) }

  describe '#execute' do
    context 'when issue sla is available' do
      it 'calls IncidentManagement::Incidents::CreateSlaService' do
        allow(issue).to receive(:sla_available?).and_return(true)

        expect_next(::IncidentManagement::Incidents::CreateSlaService, issue, current_user)
            .to receive(:execute)

        after_create_service.execute(issue)
      end
    end

    context 'when issue sla is not available' do
      it 'does not call IncidentManagement::Incidents::CreateSlaService' do
        allow(issue).to receive(:sla_available?).and_return(false)

        expect(::IncidentManagement::Incidents::CreateSlaService)
            .not_to receive(:new)

        after_create_service.execute(issue)
      end
    end
  end
end
