# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Memberships::ExportService do
  let(:group) { create(:group) }
  let(:owner_member) { create(:group_member, :owner, group: group)}
  let(:current_user) { owner_member.user }
  let(:service) { described_class.new(container: group, current_user: current_user) }

  shared_examples 'not available' do
    it 'returns a failed response' do
      response = service.execute

      expect(response.success?).to be false
      expect(response.message).to eq('Not available')
    end
  end

  describe '#execute' do
    context 'when unlicensed' do
      before do
        stub_licensed_features(export_user_permissions: false)
      end

      it_behaves_like 'not available'
    end

    context 'when licensed' do
      before do
        stub_licensed_features(export_user_permissions: true)
        group.add_member(current_user, Gitlab::Access::OWNER)
      end

      it 'is successful' do
        response = service.execute

        expect(response.success?).to be true
      end

      context 'current_user is not an owner of this group' do
        let(:service) { described_class.new(container: group, current_user: create(:user)) }

        it_behaves_like 'not available'
      end

      context 'current_user is a group developer' do
        let(:current_user) { create(:user) }

        before do
          group.add_developer(current_user)
        end

        it_behaves_like 'not available'
      end

      context 'current_user is a group maintainer' do
        let(:current_user) { create(:user) }

        before do
          group.add_maintainer(current_user)
        end

        it_behaves_like 'not available'
      end

      context 'current_user is a guest' do
        let(:current_user) { create(:user) }

        before do
          group.add_guest(current_user)
        end

        it_behaves_like 'not available'
      end

      context 'data verification' do
        let(:expiry_date) { Date.today + 1.month }

        before do
          create_list(:group_member, 4, group: group)
          create(:group_member, group: group, created_at: '2021-02-01', expires_at: expiry_date, user: create(:user, username: 'mwoolf', name: 'Max Woolf'))
          create(:group_member, :invited, group: group)
          create(:group_member, :ldap, group: group)
          create(:group_member, :blocked, group: group)
          create(:group_member, :minimal_access, group: group)
        end
        let(:csv) { CSV.parse(service.execute.payload, headers: true) }

        it 'has the correct headers' do
          expect(csv.headers).to contain_exactly('Username', 'Name', 'Access granted', 'Access expires', 'Max role', 'Source')
        end

        it 'has the correct number of rows' do
          expect(csv.size).to eq(9)
        end

        context 'a direct user', :aggregate_failures do
          let(:direct_user_row) { csv[5] }

          it 'has the correct information' do
            expect(direct_user_row[0]).to eq('mwoolf')
            expect(direct_user_row[1]).to eq('Max Woolf')
            expect(direct_user_row[2]).to eq('2021-02-01 00:00:00')
            expect(direct_user_row[3]).to eq(expiry_date.to_s)
            expect(direct_user_row[4]).to eq('Owner')
            expect(direct_user_row[5]).to eq('Direct member')
          end
        end

        context 'a user in a subgroup' do
          before do
            sub_group = create(:group, parent: group)
            create(:group_member, group: sub_group, user: create(:user, username: 'Oliver', name: 'Oliver D', email: 'oliver@test.com'))
          end

          it 'has the correct information' do
            row = csv.find { |row| row['Username'] == 'Oliver' }

            expect(row[0]).to eq('Oliver')
            expect(row[1]).to eq('Oliver D')
            expect(row[4]).to eq('Owner')
            expect(row[5]).to eq('Inherited member')
          end
        end
      end
    end
  end
end
