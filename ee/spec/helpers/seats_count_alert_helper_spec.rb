# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SeatsCountAlertHelper, :saas do
  include Devise::Test::ControllerHelpers

  let_it_be(:group) { nil }
  let_it_be(:project) { nil }
  let_it_be(:user) { create(:user) }

  before do
    assign(:project, project)
    assign(:group, group)
    allow(helper).to receive(:current_user).and_return(user)
  end

  shared_examples 'learn more link is built' do
    it 'builds the correct link' do
      expect(helper.learn_more_link).to match %r{<a.*href="#{help_page_path('subscriptions/quarterly_reconciliation')}".*>.+</a>}m
    end
  end

  shared_examples 'seats info are not populated' do
    it 'sets remaining seats count to nil' do
      expect(helper.remaining_seats_count).to be_nil
    end

    it 'sets total seats count to nil' do
      expect(helper.total_seats_count).to be_nil
    end
  end

  shared_examples 'seats info are populated' do
    it 'sets remaining seats count to the correct number' do
      expect(helper.remaining_seats_count).to eq(14)
    end

    it 'sets total seats count to the correct number' do
      expect(helper.total_seats_count).to eq(15)
    end
  end

  shared_examples 'group info are populated' do
    it 'builds the correct link' do
      expect(helper.seats_usage_link).to match %r{<a.*href="/groups/#{context.name}/-/usage_quotas#seats-quota-tab\".*>.+</a>}m
    end

    it 'has a group name' do
      expect(helper.group_name).to eq(context.name)
    end
  end

  shared_examples 'group info are not populated' do
    it 'does not build the correct link' do
      expect(helper.seats_usage_link).to be_nil
    end

    it 'does not have a group name' do
      expect(helper.group_name).to be_nil
    end
  end

  shared_examples 'alert is not displayed while some info are' do
    it_behaves_like 'learn more link is built'

    it_behaves_like 'seats info are not populated'

    it_behaves_like 'group info are not populated'

    it 'does not show the alert' do
      expect(helper.show_seats_count_alert?).to be false
    end
  end

  shared_examples 'alert is displayed' do
    include_examples 'learn more link is built'

    include_examples 'seats info are populated'

    include_examples 'group info are populated'

    it 'does show the alert' do
      expect(helper.show_seats_count_alert?).to be true
    end
  end

  shared_examples 'alert is not displayed' do
    include_examples 'learn more link is built'

    include_examples 'seats info are populated'

    include_examples 'group info are populated'

    it 'does not show the alert' do
      expect(helper.show_seats_count_alert?).to be false
    end
  end

  shared_examples 'common cases for users' do
    let_it_be(:gitlab_subscription) do
      create(:gitlab_subscription, namespace: context, plan_code: Plan::ULTIMATE, seats: 15, seats_in_use: 1)
    end

    describe 'without a owner' do
      before do
        context.add_user(user, GroupMember::DEVELOPER)
        helper.display_seats_count_alert!
      end

      include_examples 'alert is not displayed'
    end

    describe 'with a owner' do
      before do
        context.add_owner(user)
      end

      context 'without display seats count' do
        include_examples 'alert is not displayed'
      end

      context 'with display seats count' do
        before do
          helper.display_seats_count_alert!
        end

        include_examples 'alert is displayed'
      end
    end
  end

  it 'sets @display_seats_count_alert to true' do
    expect(helper.instance_variable_get(:@display_seats_count_alert)).to be nil

    helper.display_seats_count_alert!

    expect(helper.instance_variable_get(:@display_seats_count_alert)).to be true
  end

  describe 'with no subscription' do
    include_examples 'alert is not displayed while some info are'
  end

  describe 'outside a group or project context' do
    before do
      helper.display_seats_count_alert!
    end

    include_examples 'alert is not displayed while some info are'
  end

  describe 'within a group context' do
    let_it_be(:group) { create(:group) }
    let_it_be(:context) { group }
    let_it_be(:project) { nil }

    include_examples 'common cases for users'
  end

  describe 'within a subgroup context' do
    let_it_be(:context) { create(:group) }
    let_it_be(:group) { create(:group, parent: context) }
    let_it_be(:project) { nil }

    include_examples 'common cases for users'
  end

  describe 'within a project context' do
    let_it_be(:group) { nil }
    let_it_be(:context) { create(:group) }
    let_it_be(:project) { create(:project, namespace: context) }

    include_examples 'common cases for users'
  end

  describe 'within a user namespace context' do
    let_it_be(:project) { create(:project) }

    before do
      helper.display_seats_count_alert!
    end

    it 'does show the alert' do
      expect(helper.show_seats_count_alert?).to be false
    end
  end
end
