# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/billings/_eoa_bronze_plan_banner.html.haml' do
  let_it_be(:user) { create(:user) }

  let(:eoa_bronze_plan_end_date) { Date.current + 5.days }

  stub_feature_flags(show_billing_eoa_banner: true)

  shared_examples 'current time' do
    before do
      allow(namespace).to receive(:actual_plan_name).and_return(::Plan::BRONZE)
    end

    it 'displays the banner' do
      travel_to(eoa_bronze_plan_end_date - 1.day) do
        render

        expect(rendered).to have_content("End of availability for the Bronze Plan")
      end
    end
  end

  shared_examples 'past eoa date' do
    before do
      allow(namespace).to receive(:actual_plan_name).and_return(::Plan::BRONZE)
    end

    it 'does not display the banner' do
      travel_to(eoa_bronze_plan_end_date + 1.day) do
        render

        expect(rendered).not_to have_content("End of availability for the Bronze Plan")
      end
    end
  end

  shared_examples 'with show_billing_eoa_banner turned off' do
    before do
      stub_feature_flags(show_billing_eoa_banner: false)
      allow(namespace).to receive(:actual_plan_name).and_return(::Plan::BRONZE)
    end

    it 'does not display the banner' do
      travel_to(eoa_bronze_plan_end_date - 1.day) do
        render

        expect(rendered).not_to have_content("End of availability for the Bronze Plan")
      end
    end
  end

  shared_examples 'with a different plan than Bronze' do
    before do
      allow(namespace).to receive(:actual_plan_name).and_return(::Plan::PREMIUM)
    end

    it 'does not display the banner' do
      travel_to(eoa_bronze_plan_end_date - 1.day) do
        render

        expect(rendered).not_to have_content("End of availability for the Bronze Plan")
      end
    end
  end

  shared_examples 'when user dismissed the banner' do
    before do
      allow(namespace).to receive(:actual_plan_name).and_return(::Plan::BRONZE)
      allow(view).to receive(:user_dismissed?).with(::EE::Users::CalloutsHelper::EOA_BRONZE_PLAN_BANNER).and_return(true)
    end

    it 'does not display the banner' do
      travel_to(eoa_bronze_plan_end_date - 1.day) do
        render

        expect(rendered).not_to have_content("End of availability for the Bronze Plan")
      end
    end
  end

  before do
    allow(view).to receive(:eoa_bronze_plan_end_date).and_return(eoa_bronze_plan_end_date)
    allow(view).to receive(:user_dismissed?).with(::EE::Users::CalloutsHelper::EOA_BRONZE_PLAN_BANNER).and_return(false)
  end

  context 'with group namespace' do
    let(:group) { create(:group) }
    let(:current_user) { user }

    before do
      group.add_owner(current_user.id)
      allow(group).to receive(:actual_plan_name).and_return(::Plan::BRONZE)
      allow(view).to receive(:namespace).and_return(group)
      allow(view).to receive(:current_user).and_return(current_user)
    end

    it_behaves_like 'current time' do
      let(:namespace) { group }
    end

    it_behaves_like 'past eoa date' do
      let(:namespace) { group }
    end

    it_behaves_like 'with show_billing_eoa_banner turned off' do
      let(:namespace) { group }
    end

    it_behaves_like 'with a different plan than Bronze' do
      let(:namespace) { group }
    end

    it_behaves_like 'when user dismissed the banner' do
      let(:namespace) { group }
    end
  end

  context 'with personal namespace' do
    let(:current_user) { user }

    before do
      allow(current_user.namespace).to receive(:actual_plan_name).and_return(::Plan::BRONZE)
      allow(view).to receive(:namespace).and_return(current_user.namespace)
    end

    it_behaves_like 'current time' do
      let(:namespace) { current_user.namespace }
    end

    it_behaves_like 'past eoa date' do
      let(:namespace) { current_user.namespace }
    end

    it_behaves_like 'with show_billing_eoa_banner turned off' do
      let(:namespace) { current_user.namespace }
    end

    it_behaves_like 'with a different plan than Bronze' do
      let(:namespace) { current_user.namespace }
    end

    it_behaves_like 'when user dismissed the banner' do
      let(:namespace) { current_user.namespace }
    end
  end
end
