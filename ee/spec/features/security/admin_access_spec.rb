# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin::Projects", feature_category: :groups_and_projects do
  include AccessMatchers

  describe "GET /admin/projects" do
    subject { admin_projects_path }

    it { is_expected.to be_denied_for :auditor }
  end

  describe "GET /admin/users" do
    subject { admin_users_path }

    it { is_expected.to be_denied_for :auditor }
  end

  describe "GET /admin/hooks" do
    subject { admin_hooks_path }

    it { is_expected.to be_denied_for :auditor }
  end
end
