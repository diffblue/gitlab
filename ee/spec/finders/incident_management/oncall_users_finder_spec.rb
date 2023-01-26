# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallUsersFinder do
  let_it_be_with_refind(:project) { create(:project) }

  # Project 1             Shift 1          Shift 2          Shift 3
  # s1 -> r1 [p1]     | user 1; saved | user 1; unsaved | user 1; unsaved |
  #    -> r2 [p1, p2] | user 2; saved | user 3; saved   | user 2; unsaved |
  # s2 -> r1 [p1]     | user 4; saved | user 4; unsaved | user 4; unsaved |
  #    -> r2 [p1]     | user 1; saved | user 1; unsaved | user 1; unsaved |
  #    -> r3          |     N/A       |      N/A        |       N/A       |
  #
  # Project 2
  # s1 -> r1 [p1, p2] | user 5; saved | user 2; saved   | user 5; unsaved |

  # Schedule 1 / Rotation 1
  let_it_be(:s1) { create(:incident_management_oncall_schedule, project: project) }
  let_it_be(:s1_r1) { create(:incident_management_oncall_rotation, :with_participants, schedule: s1) }
  let_it_be(:s1_r1_p1) { s1_r1.participants.first }
  let_it_be(:user_1) { s1_r1_p1.user }
  let_it_be(:s1_r1_shift1) { create(:incident_management_oncall_shift, participant: s1_r1_p1) }

  # Schedule 1 / Rotation 2
  let_it_be(:s1_r2) { create(:incident_management_oncall_rotation, :with_participants, schedule: s1) }
  let_it_be(:s1_r2_p1) { s1_r2.participants.first }
  let_it_be(:user_2) { s1_r2_p1.user }
  let_it_be(:s1_r2_shift1) { create(:incident_management_oncall_shift, participant: s1_r2_p1) }
  let_it_be(:s1_r2_p2) { create(:incident_management_oncall_participant, rotation: s1_r2) }
  let_it_be(:user_3) { s1_r2_p2.user }
  let_it_be(:s1_r2_shift2) { create(:incident_management_oncall_shift, participant: s1_r2_p2, starts_at: s1_r2_shift1.ends_at) }

  # Schedule 2 / Rotation 1
  let_it_be(:s2) { create(:incident_management_oncall_schedule, project: project) }
  let_it_be(:s2_r1) { create(:incident_management_oncall_rotation, :with_participants, schedule: s2) }
  let_it_be(:s2_r1_p1) { s2_r1.participants.first }
  let_it_be(:user_4) { s2_r1_p1.user }
  let_it_be(:s2_r1_shift1) { create(:incident_management_oncall_shift, participant: s2_r1_p1) }

  # Schedule 2 / Rotation 2 - has same user as s1_r1_p1
  let_it_be(:s2_r2) { create(:incident_management_oncall_rotation, schedule: s2) }
  let_it_be(:s2_r2_p1) { create(:incident_management_oncall_participant, user: user_1, rotation: s2_r2) }
  let_it_be(:s2_r2_shift1) { create(:incident_management_oncall_shift, participant: s2_r2_p1) }

  # Schedule 2 / Rotation 3 - has no participants
  let_it_be(:s2_r3) { create(:incident_management_oncall_rotation, schedule: s2) }

  # Other Project - has same user as s1_r2_p1
  let_it_be(:proj2_s1_r1_p1) { create(:incident_management_oncall_participant) } # user_5
  let_it_be(:proj2_s1_r1_shift1) { create(:incident_management_oncall_shift, participant: proj2_s1_r1_p1) }
  let_it_be(:proj2_s1_r1) { proj2_s1_r1_p1.rotation }
  let_it_be(:proj2_s1_r1_p2) { create(:incident_management_oncall_participant, :with_developer_access, user: user_2, rotation: proj2_s1_r1) }
  let_it_be(:proj2_s1_r1_shift2) { create(:incident_management_oncall_shift, participant: proj2_s1_r1_p2, starts_at: proj2_s1_r1_shift1.ends_at) }

  let(:oncall_at) { Time.current }
  let(:schedule) { nil }

  describe '#execute' do
    subject(:execute) { described_class.new(project, oncall_at: oncall_at, schedule: schedule).execute }

    context 'when feature is available' do
      before do
        stub_licensed_features(oncall_schedules: true)
      end

      context 'without parameters uses current time' do
        subject(:execute) { described_class.new(project).execute }

        it { is_expected.to contain_exactly(user_1, user_2, user_4) }
      end

      context 'with :schedule paramater specified' do
        let(:schedule) { s1 }

        it { is_expected.to contain_exactly(user_1, user_2) }
      end

      context 'with :oncall_at parameter specified' do
        let(:during_first_shift) { Time.current }
        let(:during_second_shift) { s1_r2_shift2.starts_at + 5.minutes }
        let(:after_second_shift) { s1_r2_shift2.ends_at + 5.minutes }
        let(:before_shifts) { s1_r1.starts_at - 15.minutes }

        context 'with all persisted shifts for oncall_at time' do
          let(:oncall_at) { during_first_shift }

          it { is_expected.to contain_exactly(user_1, user_2, user_4) }

          it 'does not attempt to generate shifts' do
            expect(IncidentManagement::OncallShiftGenerator).not_to receive(:new)

            execute
          end
        end

        context 'with some persisted shifts for oncall_at time' do
          let(:oncall_at) { during_second_shift }

          it { is_expected.to contain_exactly(user_1, user_3, user_4) }

          it 'does not run additional queries for each persisted shift' do
            query_count = ActiveRecord::QueryRecorder.new { execute }

            create(:incident_management_oncall_shift, participant: s1_r1_p1, starts_at: s1_r1_shift1.ends_at)

            expect { described_class.new(project, oncall_at: oncall_at).execute }.not_to exceed_query_limit(query_count)
          end
        end

        context 'with no persisted shifts for oncall_at time', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/343506' do
          let(:oncall_at) { after_second_shift }

          it { is_expected.to contain_exactly(user_1, user_2, user_4) }
        end

        context 'before rotations have started' do
          let(:oncall_at) { before_shifts }

          it { is_expected.to be_empty }
        end

        it 'does not require additional queries to generate shifts' do
          query_count = ActiveRecord::QueryRecorder.new { described_class.new(project, oncall_at: during_first_shift).execute }

          expect { described_class.new(project, oncall_at: after_second_shift).execute }
            .not_to exceed_query_limit(query_count)
        end
      end
    end

    context 'when feature is not avaiable' do
      before do
        stub_licensed_features(oncall_schedules: false)
      end

      it { is_expected.to be_none }
    end
  end
end
