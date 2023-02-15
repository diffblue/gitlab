# frozen_string_literal: true

RSpec.shared_examples 'updating issuable health status' do
  context 'updating health_status' do
    let(:current_user) { create(:user) }
    let(:opts) { { health_status: 1 } }
    let(:service) { described_class.new(container: parent, current_user: current_user, params: opts) }

    context 'when feature is not available' do
      it 'does not update issue health status' do
        expect { service.execute(issuable) }.not_to change { issuable.health_status }
      end
    end

    context 'when feature is available' do
      before do
        stub_licensed_features(issuable_health_status: true, epics: true)
      end

      context 'when user has reporter permissions' do
        before do
          issuable.resource_parent.add_reporter(current_user)
        end

        it 'updates issuable with given health_status' do
          expect { service.execute(issuable) }.to change { issuable.health_status }.to('on_track')
        end
      end

      context 'when user does not have permissions' do
        it 'does not update issuable status' do
          expect { service.execute(issuable) }.not_to change { issuable.health_status }
        end
      end
    end
  end
end
