# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ExportPolicy, feature_category: :vulnerability_management do
  let!(:user) { create(:user) }
  let!(:project) { create(:project) }

  let(:vulnerability_export) { create(:vulnerability_export, :finished, :csv, :with_csv_file, project: project, author: author) }

  subject { described_class.new(user, vulnerability_export) }

  context 'when security dashboard is licensed' do
    before do
      stub_licensed_features(security_dashboard: true)
    end

    context 'with a user that is an author of vulnerability export' do
      let(:author) { user }

      context 'when user has access to vulnerabilities from the project' do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_allowed(:read_vulnerability_export) }
      end

      context 'when user has no access to vulnerabilities from the project' do
        it { is_expected.to be_disallowed(:read_vulnerability_export) }
      end
    end

    context 'with a user that is not an author of vulnerability export' do
      let(:author) { create(:user) }

      context 'when user has access to vulnerabilities from the project' do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_disallowed(:read_vulnerability_export) }
      end

      context 'when user has no access to vulnerabilities from the project' do
        it { is_expected.to be_disallowed(:read_vulnerability_export) }
      end
    end
  end

  context 'when security dashboard is not licensed' do
    before do
      stub_licensed_features(security_dashboard: false)
    end

    context 'with a user that is an author of vulnerability export' do
      let(:author) { user }

      context 'when user has access to vulnerabilities from the project' do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_disallowed(:read_vulnerability_export) }
      end

      context 'when user has no access to vulnerabilities from the project' do
        it { is_expected.to be_disallowed(:read_vulnerability_export) }
      end
    end

    context 'with a user that is not an author of vulnerability export' do
      let(:author) { create(:user) }

      context 'when user has access to vulnerabilities from the project' do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_disallowed(:read_vulnerability_export) }
      end

      context 'when user has no access to vulnerabilities from the project' do
        it { is_expected.to be_disallowed(:read_vulnerability_export) }
      end
    end
  end
end
