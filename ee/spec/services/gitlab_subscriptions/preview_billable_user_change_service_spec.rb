# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::GitlabSubscriptions::PreviewBillableUserChangeService do
  before do
    allow(Gitlab).to receive(:com?).and_return(true)
  end

  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:role) { :developer }

    context 'when target group exists' do
      let_it_be(:existing_user) { create(:user) }

      let(:target_group) { create(:group_with_plan) }

      before do
        target_group.add_developer(existing_user)
      end

      context 'when adding users' do
        context 'by group id' do
          subject(:execute) do
            described_class.new(
              current_user: current_user,
              target_group: target_group,
              role: role,
              add_group_id: add_group_id
            ).execute
          end

          context 'when group exists' do
            let_it_be(:group_member_1) { create(:user) }
            let_it_be(:group_member_2) { create(:user) }
            let_it_be(:group) { create(:group, :private) }
            let_it_be(:add_group_id) { group.id }

            before do
              group.add_developer(group_member_1)
              group.add_developer(group_member_2)
            end

            context 'when current_user has access to view group' do
              before do
                group.add_developer(current_user)
              end

              it 'counts group members' do
                expect(execute).to include({
                  success: true,
                  data: {
                    has_overage: false,
                    new_billable_user_count: 4,
                    seats_in_subscription: 10
                  }
                })
              end

              context 'when group contains an existing user from target group' do
                before do
                  group.add_developer(existing_user)
                end

                it 'does not count existing user' do
                  expect(execute).to include({
                    success: true,
                    data: {
                      has_overage: false,
                      new_billable_user_count: 4,
                      seats_in_subscription: 10
                    }
                  })
                end
              end
            end

            context 'when current_user does not have access to view group' do
              it 'does not count group members' do
                expect(execute).to include({
                  success: true,
                  data: {
                    has_overage: false,
                    new_billable_user_count: 1,
                    seats_in_subscription: 10
                  }
                })
              end
            end
          end

          context 'when group does not exist' do
            let_it_be(:add_group_id) { non_existing_record_id }

            it 'returns successfully' do
              expect(execute).to include({
                success: true,
                data: { has_overage: false, new_billable_user_count: 1, seats_in_subscription: 10 }
              })
            end
          end
        end

        context 'by email' do
          let_it_be(:user) { create(:user) }
          let_it_be(:add_user_emails) { [user.email, 'foo@example.com'] }

          subject(:execute) do
            described_class.new(
              current_user: current_user,
              target_group: target_group,
              role: role,
              add_user_emails: add_user_emails
            ).execute
          end

          it 'counts user emails and unassociated emails' do
            expect(execute).to include({
              success: true,
              data: {
                has_overage: false,
                new_billable_user_count: 3,
                seats_in_subscription: 10
              }
            })
          end

          context 'when email is associated with user already in target group' do
            let_it_be(:add_user_emails) { [user.email, 'foo@example.com', existing_user.email] }

            it 'does not count existing user' do
              expect(execute).to include({
                success: true,
                data: {
                  has_overage: false,
                  new_billable_user_count: 3,
                  seats_in_subscription: 10
                }
              })
            end
          end
        end

        context 'by user id' do
          let_it_be(:add_user_ids) { [non_existing_record_id] }

          subject(:execute) do
            described_class.new(
              current_user: current_user,
              target_group: target_group,
              role: role,
              add_user_ids: add_user_ids
            ).execute
          end

          it 'returns successfully' do
            expect(execute).to include({
              success: true,
              data: {
                has_overage: false,
                new_billable_user_count: 2,
                seats_in_subscription: 10
              }
            })
          end

          context 'when id is associated with user already in target group' do
            let_it_be(:add_user_ids) { [non_existing_record_id, existing_user.id] }

            it 'does not count existing user' do
              expect(execute).to include({
                success: true,
                data: {
                  has_overage: false,
                  new_billable_user_count: 2,
                  seats_in_subscription: 10
                }
              })
            end
          end
        end

        context 'with guest role' do
          let_it_be(:role) { :guest }

          subject(:execute) do
            described_class.new(
              current_user: current_user,
              target_group: target_group,
              role: role,
              add_user_ids: [non_existing_record_id]
            ).execute
          end

          context 'when target group does not charge for guests' do
            before do
              allow(target_group).to receive(:exclude_guests?).and_return true
            end

            it 'does not count added users' do
              expect(execute).to include({
                success: true,
                data: {
                  has_overage: false,
                  new_billable_user_count: 1,
                  seats_in_subscription: 10
                }
              })
            end
          end

          context 'when target group charges for guests' do
            before do
              allow(target_group).to receive(:exclude_guests?).and_return false
            end

            it 'counts added users' do
              expect(execute).to include({
                success: true,
                data: {
                  has_overage: false,
                  new_billable_user_count: 2,
                  seats_in_subscription: 10
                }
              })
            end
          end
        end
      end

      context 'when added users results in an overage' do
        let_it_be(:add_user_ids) do
          10.times.map do |i| # rubocop:disable Performance/TimesMap
            non_existing_record_id - i
          end
        end

        subject(:execute) do
          described_class.new(
            current_user: current_user,
            target_group: target_group,
            role: role,
            add_user_ids: add_user_ids
          ).execute
        end

        it 'sets has_overage: true' do
          expect(execute).to include({
            success: true,
            data: {
              has_overage: true,
              new_billable_user_count: 11,
              seats_in_subscription: 10
            }
          })
        end
      end
    end
  end
end
