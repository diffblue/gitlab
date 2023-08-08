# frozen_string_literal: true

RSpec.shared_examples 'trial widget menu items' do
  let(:menu) { described_class.new(context) }
  let(:user) { instance_double(User) }

  describe '#render?' do
    using RSpec::Parameterized::TableSyntax

    let(:group) { instance_double(Group, trial_active?: trial_active) }

    before do
      stub_application_setting(check_namespace_plan: trials_available)
      allow(menu).to receive(:can?).and_call_original
      allow(menu).to receive(:can?).with(user, :admin_namespace, group).and_return(user_can_admin_group)
      allow(group).to receive(:root_ancestor).and_return(group)
    end

    subject { menu.render? }

    where(
      trials_available: [true, false],
      trial_active: [true, false],
      user_can_admin_group: [true, false]
    )

    with_them do
      it { is_expected.to eq(trials_available && trial_active && user_can_admin_group) }
    end
  end

  describe '#menu_partial_options' do
    let(:group) { build(:group) }

    subject { menu.menu_partial_options }

    it 'provides expected options' do
      result = {
        root_group: group,
        trial_status: an_instance_of(GitlabSubscriptions::TrialStatus)
      }

      is_expected.to match(result)
    end
  end
end
