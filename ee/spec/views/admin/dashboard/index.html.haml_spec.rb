# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/dashboard/index.html.haml' do
  include Devise::Test::ControllerHelpers

  let(:reflections) do
    Gitlab::Database.database_base_models.transform_values do |base_model|
      ::Gitlab::Database::Reflection.new(base_model)
    end
  end

  before do
    counts = Admin::DashboardController::COUNTED_ITEMS.index_with { 100 }

    assign(:counts, counts)
    assign(:projects, create_list(:project, 1))
    assign(:users, create_list(:user, 1))
    assign(:groups, create_list(:group, 1))
    assign(:database_reflections, reflections)

    allow(view).to receive(:admin?).and_return(true)
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
  end

  context 'when license is present' do
    before do
      assign(:license, create(:license))
    end

    it 'includes notices above license breakdown' do
      assign(:notices, [{ type: :alert, message: 'An alert' }])

      render

      expect(rendered).to have_content /An alert.*Users in License/
    end

    it 'includes license overview' do
      render

      expect(rendered).to have_content _('License overview')
      expect(rendered).to have_content _('Plan:')
      expect(rendered).to have_content s_('Subscriptions|End date:')
      expect(rendered).to have_content _('Licensed to:')
      expect(rendered).to have_link _('View details'), href: admin_subscription_path
    end

    it 'includes license breakdown' do
      render

      expect(rendered).to have_content _('Users in License')
      expect(rendered).to have_content _('Billable Users')
      expect(rendered).to have_content _('Maximum Users')
      expect(rendered).to have_content _('Users over License')
    end
  end

  context 'when license is not present' do
    it 'does not show content' do
      render

      expect(rendered).not_to have_content "USERS IN LICENSE"
    end
  end

  describe 'license expirations' do
    shared_examples_for 'expiration message' do |start_date:, expire_date:, is_trial:, message:|
      before do
        assign(
          :license,
          create(
            :license,
            restrictions: { trial: is_trial },
            data: create(
              :gitlab_license,
              licensee: { 'Company' => 'GitLab', 'Email' => 'test@gitlab.com' },
              starts_at: start_date,
              expires_at: expire_date
            ).export
          )
        )
      end

      it "shows '#{message}'" do
        render
        expect(rendered).to have_content message.to_s
      end
    end

    context 'when paid license is loaded' do
      context 'when is active' do
        today = Date.current
        it_behaves_like 'expiration message',
          start_date: today - 30.days,
          expire_date: today + 30.days,
          is_trial: false,
          message: "#{s_('Subscriptions|End date:')} #{(today + 30.days).strftime('%b %-d, %Y')}"
      end

      context 'when is expired' do
        today = Date.current
        it_behaves_like 'expiration message',
          start_date: today - 60.days,
          expire_date: today - 30.days,
          is_trial: false,
          message: "#{_('Expired:')} #{(today - 30.days).strftime('%b %-d, %Y')}"
      end

      context 'when never expires' do
        today = Date.current
        it_behaves_like 'expiration message',
          start_date: today - 30.days,
          expire_date: nil,
          is_trial: false,
          message: "#{s_('Subscriptions|End date:')} #{s_('Subscriptions|None')}"
      end
    end

    context 'when trial license is loaded' do
      context 'when is active' do
        today = Date.current
        days_left = 23
        it_behaves_like 'expiration message',
          start_date: today - 30.days,
          expire_date: today + days_left.days,
          is_trial: true,
          message: "#{s_('Subscriptions|End date:')} Free trial will expire in #{days_left} days"
      end

      context 'when is expired' do
        today = Date.current
        it_behaves_like 'expiration message',
          start_date: today - 60.days,
          expire_date: today - 30.days,
          is_trial: true,
          message: "#{_('Expired:')} #{(today - 30.days).strftime('%b %-d, %Y')}"
      end

      context 'when never expires' do
        today = Date.current
        it_behaves_like 'expiration message',
          start_date: today - 30.days,
          expire_date: nil,
          is_trial: true,
          message: "#{s_('Subscriptions|End date:')} #{s_('Subscriptions|None')}"
      end
    end
  end
end
