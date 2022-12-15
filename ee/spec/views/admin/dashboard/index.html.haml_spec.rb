# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/dashboard/index.html.haml' do
  include Devise::Test::ControllerHelpers

  before do
    counts = Admin::DashboardController::COUNTED_ITEMS.index_with { 100 }

    assign(:counts, counts)
    assign(:projects, create_list(:project, 1))
    assign(:users, create_list(:user, 1))
    assign(:groups, create_list(:group, 1))

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

      expect(rendered).to have_content "License overview"
      expect(rendered).to have_content "Plan:"
      expect(rendered).to have_content "Expires:"
      expect(rendered).to have_content "Licensed to:"
      expect(rendered).to have_link 'View details', href: admin_subscription_path
    end

    it 'includes license breakdown' do
      render

      expect(rendered).to have_content "Users in License"
      expect(rendered).to have_content "Billable Users"
      expect(rendered).to have_content "Maximum Users"
      expect(rendered).to have_content "Users over License"
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
        assign(:license, create(:license,
                                restrictions: { trial: is_trial },
                                data: create(:gitlab_license,
                                             licensee: { 'Company' => 'GitLab', 'Email' => 'test@gitlab.com' },
                                             starts_at: start_date, expires_at: expire_date).export))
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
                        message: "Expires: #{(today + 30.days).strftime('%b %-d, %Y')}"
      end

      context 'when is expired' do
        today = Date.current
        it_behaves_like 'expiration message',
                        start_date: today - 60.days,
                        expire_date: today - 30.days,
                        is_trial: false,
                        message: "Expired: #{(today - 30.days).strftime('%b %-d, %Y')}"
      end

      context 'when never expires' do
        today = Date.current
        it_behaves_like 'expiration message',
                        start_date: today - 30.days,
                        expire_date: nil,
                        is_trial: false,
                        message: "Expires: Never"
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
                        message: "Expires: Free trial will expire in #{days_left} days"
      end

      context 'when is expired' do
        today = Date.current
        it_behaves_like 'expiration message',
                        start_date: today - 60.days,
                        expire_date: today - 30.days,
                        is_trial: true,
                        message: "Expired: #{(today - 30.days).strftime('%b %-d, %Y')}"
      end

      context 'when never expires' do
        today = Date.current
        it_behaves_like 'expiration message',
                        start_date: today - 30.days,
                        expire_date: nil,
                        is_trial: true,
                        message: "Expires: Never"
      end
    end
  end
end
