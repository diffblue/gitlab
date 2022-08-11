# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::Notification do
  include ::Ci::MinutesHelpers

  let_it_be(:user) { create(:user) }
  let(:shared_runners_enabled) { true }
  let!(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: shared_runners_enabled) }
  let_it_be(:group, refind: true) { create(:group) }

  let(:injected_group) { group }
  let(:injected_project) { project }

  shared_examples 'queries for notifications' do
    context 'without limit' do
      it { is_expected.to be_falsey }
    end

    context 'when limit is defined' do
      context 'when limit not yet exceeded' do
        let(:group) { create(:group, :with_not_used_build_minutes_limit) }

        it { is_expected.to be_falsey }
      end

      context 'when minutes are not yet set' do
        let(:group) { create(:group, :with_ci_minutes, ci_minutes_limit: nil) }

        it { is_expected.to be_falsey }
      end
    end
  end

  shared_examples 'has notifications' do
    shared_examples 'aware of dismission cookie' do
      it 'does not show when cookie is set' do
        expect(subject.show?(user, { subject.dismiss_cookie_id => 'true' })).to be_falsey
      end
    end

    context 'when usage has reached a notification level' do
      before do
        group.shared_runners_minutes_limit = 20
      end

      context 'when at the warning level' do
        let(:group) { create(:group, :with_ci_minutes, ci_minutes_used: 16) }

        describe '#show?' do
          it 'has warning notification' do
            expect(subject.show?(user)).to be_truthy
            expect(subject.text).to match(/.*\shas 30% or less Shared Runner Pipeline minutes remaining/)
            expect(subject.style).to eq :warning
          end

          it_behaves_like 'aware of dismission cookie'
        end

        describe '#running_out?' do
          it 'is running out of minutes' do
            expect(subject.running_out?).to be_truthy
          end
        end

        describe '#no_remaining_minutes?' do
          it 'has not ran out of minutes' do
            expect(subject.no_remaining_minutes?).to be_falsey
          end
        end

        describe '#stage_percentage' do
          it 'provides percentage for current alert level' do
            expect(subject.stage_percentage).to eq 30
          end
        end
      end

      context 'when at the danger level' do
        let(:group) { create(:group, :with_ci_minutes, ci_minutes_used: 19) }

        describe '#show?' do
          it 'has danger notification' do
            expect(subject.show?(user)).to be_truthy
            expect(subject.text).to match(/.*\shas 5% or less Shared Runner Pipeline minutes remaining/)
            expect(subject.style).to eq :danger
          end

          it_behaves_like 'aware of dismission cookie'
        end

        describe '#running_out?' do
          it 'is running out of minutes' do
            expect(subject.running_out?).to be_truthy
          end
        end

        describe '#no_remaining_minutes?' do
          it 'has not ran out of minutes' do
            expect(subject.no_remaining_minutes?).to be_falsey
          end
        end

        describe '#stage_percentage' do
          it 'provides percentage for current alert level' do
            expect(subject.stage_percentage).to eq 5
          end
        end
      end

      context 'when right at the limit for notification' do
        let(:group) { create(:group, :with_ci_minutes, ci_minutes_used: 14) }

        describe '#show?' do
          it 'has warning notification' do
            expect(subject.show?(user)).to be_truthy
            expect(subject.text).to match(/.*\shas 30% or less Shared Runner Pipeline minutes remaining/)
            expect(subject.style).to eq :warning
          end

          it_behaves_like 'aware of dismission cookie'
        end

        describe '#running_out?' do
          it 'is running out of minutes' do
            expect(subject.running_out?).to be_truthy
          end
        end

        describe '#no_remaining_minutes?' do
          it 'has not ran out of minutes' do
            expect(subject.no_remaining_minutes?).to be_falsey
          end
        end

        describe '#stage_percentage' do
          it 'provides percentage for current alert level' do
            expect(subject.stage_percentage).to eq 30
          end
        end
      end

      context 'when usage has exceeded the limit' do
        let(:group) { create(:group, :with_used_build_minutes_limit) }

        describe '#show?' do
          it 'has exceeded notification' do
            expect(subject.show?(user)).to be_truthy
            expect(subject.text).to match(/.*\shas exceeded its pipeline minutes quota/)
            expect(subject.style).to eq :danger
          end

          it_behaves_like 'aware of dismission cookie'
        end

        describe '#running_out?' do
          it 'does not have any minutes left' do
            expect(subject.running_out?).to be_falsey
          end
        end

        describe '#no_remaining_minutes?' do
          it 'has run out of minutes out of minutes' do
            expect(subject.no_remaining_minutes?).to be_truthy
          end
        end

        describe '#stage_percentage' do
          it 'provides percentage for current alert level' do
            expect(subject.stage_percentage).to eq 0
          end
        end
      end
    end
  end

  shared_examples 'not eligible to see notifications' do
    before do
      group.shared_runners_minutes_limit = 10
      set_ci_minutes_used(group, 8)
    end

    context 'when not permitted to see notifications' do
      describe '#show?' do
        it 'has no notifications set' do
          expect(subject.show?(user)).to be_falsey
        end
      end
    end
  end

  context 'when at project level' do
    context 'when eligible to see notifications' do
      before do
        group.add_owner(user)
      end

      describe '#show?' do
        it_behaves_like 'queries for notifications' do
          subject do
            threshold = described_class.new(injected_project, nil)
            threshold.show?(user)
          end
        end
      end

      it_behaves_like 'has notifications' do
        subject { described_class.new(injected_project, nil) }
      end
    end

    it_behaves_like 'not eligible to see notifications' do
      subject { described_class.new(injected_project, nil) }
    end

    context 'when user is not authenticated' do
      let(:user) { nil }

      it_behaves_like 'not eligible to see notifications' do
        subject { described_class.new(injected_project, nil) }
      end
    end

    context 'when user is not in the correct role' do
      before do
        group.add_developer user
      end

      it_behaves_like 'not eligible to see notifications' do
        subject { described_class.new(injected_project, nil) }
      end
    end
  end

  context 'when at namespace level' do
    context 'when eligible to see notifications' do
      before do
        group.add_owner(user)
      end

      context 'with a project that has runners enabled inside namespace' do
        describe '#show?' do
          it_behaves_like 'queries for notifications' do
            subject do
              threshold = described_class.new(nil, injected_group)
              threshold.show?(user)
            end
          end
        end

        it_behaves_like 'has notifications' do
          subject { described_class.new(nil, injected_group) }
        end
      end

      context 'with no projects that have runners enabled inside namespace' do
        it_behaves_like 'not eligible to see notifications' do
          let(:shared_runners_enabled) { false }
          subject { described_class.new(nil, injected_group) }
        end
      end
    end

    it_behaves_like 'not eligible to see notifications' do
      subject { described_class.new(nil, injected_group) }
    end

    context 'when user is not authenticated' do
      let(:user) { nil }

      it_behaves_like 'not eligible to see notifications' do
        subject { described_class.new(injected_project, nil) }
      end
    end

    context 'when user is not in the correct role' do
      before do
        group.add_developer user
      end

      it_behaves_like 'not eligible to see notifications' do
        subject { described_class.new(injected_project, nil) }
      end
    end
  end
end
