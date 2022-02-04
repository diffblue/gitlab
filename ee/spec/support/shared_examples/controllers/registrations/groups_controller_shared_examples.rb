# frozen_string_literal: true

RSpec.shared_examples 'hides email confirmation warning' do
  RSpec::Matchers.define :set_confirm_warning_for do |email|
    match do |response|
      expect(controller).to set_flash.now[:warning].to include("Please check your email (#{email}) to verify that you own this address and unlock the power of CI/CD.")
    end
  end

  context 'with an unconfirmed email address present' do
    let(:user) { create(:user, confirmed_at: nil, unconfirmed_email: 'unconfirmed@gitlab.com') }

    it { is_expected.not_to set_confirm_warning_for(user.unconfirmed_email) }
  end

  context 'without an unconfirmed email address present' do
    let(:user) { create(:user, confirmed_at: nil) }

    it { is_expected.not_to set_confirm_warning_for(user.email) }
  end
end

RSpec.shared_examples "Registrations::GroupsController GET #new" do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let(:dev_env_or_com) { true }

  subject { get :new }

  context 'with an unauthenticated user' do
    it { is_expected.to have_gitlab_http_status(:redirect) }
    it { is_expected.to redirect_to(new_user_session_path) }
  end

  context 'with an authenticated user' do
    before do
      sign_in(user)
      allow(::Gitlab).to receive(:dev_env_or_com?).and_return(dev_env_or_com)
    end

    context 'when on .com' do
      it { is_expected.to have_gitlab_http_status(:ok) }
      it { is_expected.to render_template(:new) }

      it 'assigns the group variable to a new Group with the default group visibility', :aggregate_failures do
        subject
        expect(assigns(:group)).to be_a_new(Group)

        expect(assigns(:group).visibility_level).to eq(Gitlab::CurrentSettings.default_group_visibility)
      end

      context 'user without the ability to create a group' do
        let(:user) { create(:user, can_create_group: false) }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      it 'tracks an event for the combined_registration experiment', :experiment do
        expect(experiment(:combined_registration)).to track(:view_new_group_action).on_next_instance

        subject
      end
    end

    context 'when not on .com' do
      let(:dev_env_or_com) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    it_behaves_like 'hides email confirmation warning'
  end
end
