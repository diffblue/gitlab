# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::Profiles::DestroyService do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:dast_profile, reload: true) { create(:dast_profile, project: project) }

  subject do
    described_class.new(
      container: project,
      current_user: user,
      params: { dast_profile: dast_profile }
    ).execute
  end

  describe '#execute' do
    context 'when on demand scan licensed feature is not available' do
      it 'communicates failure' do
        stub_licensed_features(security_on_demand_scans: false)

        expect(subject).to have_attributes(
          status: :error,
          message: 'You are not authorized to update this profile'
        )
      end
    end

    context 'when the feature is enabled' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'when the user cannot destroy a DAST profile' do
        it 'communicates failure' do
          expect(subject).to have_attributes(
            status: :error,
            message: 'You are not authorized to update this profile'
          )
        end
      end

      context 'when the user can destroy a DAST profile' do
        before do
          project.add_developer(user)
        end

        it 'returns a success status' do
          expect(subject.status).to eq(:success)
        end

        it 'deletes the dast_profile' do
          expect { subject }.to change { Dast::Profile.count }.by(-1)
        end

        it 'returns a dast_profile payload' do
          expect(subject.payload).to be_a(Dast::Profile)
        end

        context 'when the dast_profile fails to destroy' do
          it 'communicates failure' do
            allow(dast_profile).to receive(:destroy).and_return(false)

            expect(subject).to have_attributes(
              status: :error,
              message: 'Profile failed to delete'
            )
          end
        end

        context 'when the dast_profile parameter is missing' do
          let(:dast_profile) { nil }

          it 'communicates failure' do
            expect(subject).to have_attributes(
              status: :error,
              message: 'Profile parameter missing'
            )
          end
        end
      end
    end
  end
end
