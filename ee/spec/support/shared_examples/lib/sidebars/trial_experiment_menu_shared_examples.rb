# frozen_string_literal: true

RSpec.shared_examples 'trial experiment menu items' do
  describe '#render?' do
    using RSpec::Parameterized::TableSyntax

    let(:user) { instance_double(User) }
    let(:group) { instance_double(Group, trial_active?: trial_active) }
    let(:menu) { described_class.new(context) }

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
end
