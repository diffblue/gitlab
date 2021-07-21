# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::InProductMarketingEmailsService, '#execute' do
  let(:frozen_time) { Time.zone.parse('23 Mar 2021 10:14:40 UTC') }

  let_it_be(:user) { create(:user, email_opted_in: true) }

  before do
    travel_to(frozen_time)

    create(:onboarding_progress, namespace: group, created_at: frozen_time - 2.days, git_write_at: nil)
    group.add_developer(user)

    allow(Ability).to receive(:allowed?).with(user, anything, anything).and_return(true)
    allow(Notify).to receive(:in_product_marketing_email).and_return(double(deliver_later: nil))
  end

  context 'when group has a plan' do
    before do
      described_class.new(:create, 1).execute
    end

    context 'on the free plan' do
      let(:group) { create(:group_with_plan, plan: :free_plan) }

      it 'sends an email' do
        expect(Notify).to have_received(:in_product_marketing_email)
      end
    end

    context 'on a trial' do
      let(:group) { create(:group_with_plan, trial_ends_on: frozen_time + 10.days) }

      it 'does not send an email' do
        expect(Notify).not_to have_received(:in_product_marketing_email)
      end
    end

    context 'on a paid plan' do
      let(:group) { create(:group_with_plan, plan: :bronze_plan) }

      it 'does not send email' do
        expect(Notify).not_to have_received(:in_product_marketing_email)
      end
    end
  end
end
