# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Profile access", feature_category: :user_profile do
  include AccessMatchers

  describe "GET /-/profile/keys" do
    subject { profile_keys_path }

    it { is_expected.to be_allowed_for :auditor }
  end

  describe "GET /-/profile" do
    subject { profile_path }

    it { is_expected.to be_allowed_for :auditor }
  end

  describe "GET /-/profile/account" do
    subject { profile_account_path }

    it { is_expected.to be_allowed_for :auditor }
  end

  describe "GET /-/profile/preferences" do
    subject { profile_preferences_path }

    it { is_expected.to be_allowed_for :auditor }
  end

  describe "GET /-/profile/audit_log" do
    subject { audit_log_profile_path }

    it { is_expected.to be_allowed_for :auditor }
  end

  describe "GET /-/profile/notifications" do
    subject { profile_notifications_path }

    it { is_expected.to be_allowed_for :auditor }
  end
end
