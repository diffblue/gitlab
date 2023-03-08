# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SeatUsageExportService, feature_category: :purchase do
  describe '#execute', :aggregate_failures do
    let(:group) { create(:group, :private) }
    let(:owner) { create(:user, name: 'Owner', username: 'owner', state: 'active') }

    subject(:result) { described_class.new(group, owner).execute }

    context 'when user is allowed to export seat usage data' do
      let(:developer) { create(:user, name: 'Dev', username: 'dev', email: 'dev@example.org', state: 'active') }
      let(:reporter) { create(:user, name: 'Reporter', username: 'reporter', state: 'active') }

      before do
        group.add_owner(owner)
      end

      context 'when successful' do
        let(:payload) { result.payload.to_a }

        context 'when group has members' do
          before do
            public_email = create(:email, :confirmed, user: developer, email: 'public@email.org')
            developer.update!(public_email: public_email.email)

            group.add_developer(developer)
            group.add_reporter(reporter)
          end

          it 'returns csv data' do
            expect(payload).to eq([
                                    "Id,Name,Username,Email,State\n",
                                    "#{owner.id},Owner,owner,,active\n",
                                    "#{developer.id},Dev,dev,public@email.org,active\n",
                                    "#{reporter.id},Reporter,reporter,,active\n"
                                  ])
          end
        end

        context 'when group has no members' do
          it 'returns no rows' do
            finder = double
            expect(BilledUsersFinder).to receive(:new).and_return(finder)
            expect(finder).to receive(:execute).and_return({})

            expect(payload).to eq(["Id,Name,Username,Email,State\n"])
          end
        end
      end

      context 'when it fails' do
        it 'returns error' do
          finder = double

          expect(BilledUsersFinder).to receive(:new).and_return(finder)
          expect(finder).to receive(:execute).and_raise(PG::QueryCanceled)
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

          expect(result).to be_error
          expect(result.message).to eq('Failed to generate export')
        end
      end
    end

    context 'when user is not allowed to export seat usage data' do
      before do
        group.add_developer(owner)
      end

      it 'returns error' do
        expect(result).to be_error
        expect(result.message).to eq('Insufficient permissions to generate export')
      end
    end
  end
end
