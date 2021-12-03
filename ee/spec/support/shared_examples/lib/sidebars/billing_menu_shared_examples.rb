# frozen_string_literal: true

RSpec.shared_examples 'billing menu items' do
  let(:user) { instance_double(User) }
  let(:group) { instance_double(Group) }
  let(:namespace) { instance_double(Namespace) }

  before do
    allow(billing_menu).to receive(:can?).and_call_original
    allow(group).to receive(:root_ancestor).and_return(namespace)
  end

  subject(:billing_menu) { described_class.new(context) }

  context 'when the group can be administered' do
    include Rails.application.routes.url_helpers

    before do
      stub_application_setting(check_namespace_plan: true)
      allow(billing_menu).to receive(:can?).with(user, :admin_namespace, namespace).and_return(true)
    end

    describe '#title' do
      it 'displays the correct Billing menu text for the link in the side nav' do
        expect(billing_menu.title).to eq('Billing')
      end
    end

    describe '#link' do
      it 'displays the correct Billing menu text for the link in the side nav' do
        page = group_billings_path(namespace, from: :side_nav)

        expect(billing_menu.link).to eq page
      end
    end

    describe '#active_routes' do
      it 'uses page matching' do
        page = group_billings_path(namespace, from: :side_nav)

        expect(billing_menu.active_routes).to eq({ page: page })
      end
    end

    describe '#extra_nav_link_html_options' do
      it 'adds tracking attributes' do
        data = { track_action: :render, track_experiment: :billing_in_side_nav }

        expect(billing_menu.extra_nav_link_html_options).to eq({ data: data })
      end
    end

    describe '#sprite_icon' do
      it 'has the credit card icon' do
        expect(billing_menu.sprite_icon).to eq 'credit-card'
      end
    end

    describe '#extra_container_html_options' do
      it 'has the shortcut class' do
        expect(billing_menu.extra_container_html_options).to eq({ class: 'shortcuts-billings' })
      end
    end
  end

  describe '#render?' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_application_setting(check_namespace_plan: check_namespace_plan)
      allow(billing_menu).to receive(:can?).with(user, :admin_namespace, namespace).and_return(user_can_admin_namespace)
      allow(namespace).to receive(:user_namespace?).and_return(user_namespace)
    end

    subject { billing_menu.render? }

    where(
      check_namespace_plan: [true, false],
      user_can_admin_namespace: [true, false],
      user_namespace: [true, false]
    )

    with_them do
      it { is_expected.to eq(check_namespace_plan && user_can_admin_namespace && !user_namespace) }
    end
  end
end
