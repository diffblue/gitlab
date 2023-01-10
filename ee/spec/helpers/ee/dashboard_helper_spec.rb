# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DashboardHelper, type: :helper do
  let(:user) { build(:user) }

  describe '#dashboard_nav_links' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    describe 'operations dashboard link' do
      context 'when the feature is available on the license' do
        context 'and the user is authenticated' do
          before do
            stub_user_permissions_for(:operations, true)
          end

          it 'is included in the nav' do
            expect(helper.dashboard_nav_links).to include(:operations)
          end
        end

        context 'and the user is not authenticated' do
          before do
            stub_user_permissions_for(:operations, false)
          end

          it 'is not included in the nav' do
            expect(helper.dashboard_nav_links).not_to include(:operations)
          end
        end
      end

      context 'when the feature is not available on the license' do
        before do
          stub_user_permissions_for(:operations, false)
        end

        it 'is not included in the nav' do
          expect(helper.dashboard_nav_links).not_to include(:operations)
        end
      end
    end

    describe 'environments dashboard link' do
      context 'and the feature is available on the license' do
        context 'and the user is authenticated' do
          before do
            stub_user_permissions_for(:operations, true)
          end

          it 'is included in the nav' do
            expect(helper.dashboard_nav_links).to include(:environments)
          end
        end

        context 'and the user is not authenticated' do
          before do
            stub_user_permissions_for(:operations, false)
          end

          it 'is not included in the nav' do
            expect(helper.dashboard_nav_links).not_to include(:environments)
          end
        end
      end

      context 'and the feature is not available on the license' do
        before do
          stub_user_permissions_for(:operations, false)
        end

        it 'is not included in the nav' do
          expect(helper.dashboard_nav_links).not_to include(:environments)
        end
      end
    end

    describe 'security dashboard link' do
      context 'and the feature is available on the license' do
        before do
          stub_licensed_features(security_dashboard: true)
        end

        context 'and the user is authenticated' do
          before do
            stub_user_permissions_for(:security, true)
          end

          it 'is included in the nav' do
            expect(helper.dashboard_nav_links).to include(:security)
          end
        end

        context 'and the user is not authenticated' do
          before do
            stub_user_permissions_for(:security, false)
          end

          it 'is not included in the nav' do
            expect(helper.dashboard_nav_links).not_to include(:security)
          end
        end
      end

      context 'when the feature is not available on the license' do
        before do
          stub_licensed_features(security_dashboard: false)
          stub_user_permissions_for(:security, true)
        end

        it 'is not included in the nav' do
          expect(helper.dashboard_nav_links).not_to include(:security)
        end
      end
    end

    def stub_user_permissions_for(feature, enabled)
      allow(helper).to receive(:can?).with(user, :read_cross_project).and_return(false)

      can_read_operations_dashboard = enabled && feature == :operations
      can_read_instance_security_dashboard = enabled && feature == :security

      allow(helper).to receive(:can?).with(user, :read_operations_dashboard).and_return(can_read_operations_dashboard)
      allow_next_instance_of(InstanceSecurityDashboard) do |dashboard|
        allow(helper).to(
          receive(:can?).with(user, :read_instance_security_dashboard, dashboard).and_return(can_read_instance_security_dashboard)
        )
      end
    end
  end

  describe '.has_start_trial?', :do_not_mock_admin_mode_setting do
    using RSpec::Parameterized::TableSyntax

    where(:has_license, :current_user, :output) do
      false | :admin | true
      false | :user  | false
      true  | :admin | false
      true  | :user  | false
    end

    with_them do
      let(:user) { create(current_user) } # rubocop:disable Rails/SaveBang
      let(:license) { has_license && create(:license) }
      subject { helper.has_start_trial? }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(License).to receive(:current).and_return(license)
      end

      it { is_expected.to eq(output) }
    end
  end
end
