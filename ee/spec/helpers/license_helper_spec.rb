# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LicenseHelper, feature_category: :subscription_management do
  def stub_default_url_options(host: "localhost", protocol: "http", port: nil, script_name: '')
    url_options = { host: host, protocol: protocol, port: port, script_name: script_name }
    allow(Rails.application.routes).to receive(:default_url_options).and_return(url_options)
  end

  describe '#current_license_title' do
    context 'when there is a current license' do
      it 'returns the plan titleized if it has a plan associated to it' do
        custom_plan = 'custom plan'
        license = double('License', plan: custom_plan)
        allow(License).to receive(:current).and_return(license)

        expect(current_license_title).to eq(custom_plan.titleize)
      end

      it 'returns the default title if it does not have a plan associated to it' do
        license = double('License', plan: nil)
        allow(License).to receive(:current).and_return(license)

        expect(current_license_title).to eq('BillingPlans|Free')
      end
    end

    context 'when there is NOT a current license' do
      it 'returns the default title' do
        allow(License).to receive(:current).and_return(nil)

        expect(current_license_title).to eq('BillingPlans|Free')
      end
    end
  end

  describe '#seats_calculation_message' do
    subject { seats_calculation_message(license) }

    let(:license) { double('License', 'exclude_guests_from_active_count?' => exclude_guests) }

    context 'and guest are excluded from the active count' do
      let(:exclude_guests) { true }

      it 'returns the message' do
        expect(subject).to eq("Users with a Guest role or those who don't belong to a Project or Group will not use a seat from your license.")
      end
    end

    context 'and guest are NOT excluded from the active count' do
      let(:exclude_guests) { false }

      it 'returns nil' do
        expect(subject).to be_blank
      end
    end
  end

  describe '#licensed_users' do
    context 'with a restricted license count' do
      let(:license) do
        double('License', restricted?: { active_user_count: true }, restrictions: { active_user_count: 5 })
      end

      it 'returns a number as string' do
        license = double('License', restricted?: true, restrictions: { active_user_count: 5 })

        expect(licensed_users(license)).to eq '5'
      end
    end

    context 'without a restricted license count' do
      let(:license) { double('License', restricted?: false) }

      it 'returns Unlimited' do
        expect(licensed_users(license)).to eq 'Unlimited'
      end
    end
  end

  describe '#cloud_license_view_data' do
    before do
      allow(helper).to receive(:subscription_portal_manage_url).and_return('subscriptions_manage_url')
      allow(helper).to receive(:new_trial_url).and_return('new_trial_url')
    end

    context 'when there is a current license' do
      it 'returns the data for the view' do
        custom_plan = 'custom plan'
        license = double('License', plan: custom_plan)
        allow(License).to receive(:current).and_return(license)

        expect(helper.cloud_license_view_data).to eq({ has_active_license: 'true',
                                                       customers_portal_url: 'subscriptions_manage_url',
                                                       free_trial_path: 'new_trial_url',
                                                       buy_subscription_path: Gitlab::Saas.about_pricing_url,
                                                       subscription_sync_path: sync_seat_link_admin_license_path,
                                                       license_remove_path: admin_license_path,
                                                       congratulation_svg_path: helper.image_path('illustrations/illustration-congratulation-purchase.svg'),
                                                       subscription_activation_banner_callout_name: ::EE::Users::CalloutsHelper::CL_SUBSCRIPTION_ACTIVATION,
                                                       license_usage_file_path: admin_license_usage_export_path(format: :csv) })
      end
    end

    context 'when there is no current license' do
      it 'returns the data for the view' do
        allow(License).to receive(:current).and_return(nil)

        expect(helper.cloud_license_view_data).to eq({ has_active_license: 'false',
                                                       customers_portal_url: 'subscriptions_manage_url',
                                                       free_trial_path: 'new_trial_url',
                                                       buy_subscription_path: Gitlab::Saas.about_pricing_url,
                                                       subscription_sync_path: sync_seat_link_admin_license_path,
                                                       license_remove_path: admin_license_path,
                                                       congratulation_svg_path: helper.image_path('illustrations/illustration-congratulation-purchase.svg'),
                                                       subscription_activation_banner_callout_name: ::EE::Users::CalloutsHelper::CL_SUBSCRIPTION_ACTIVATION,
                                                       license_usage_file_path: admin_license_usage_export_path(format: :csv) })
      end
    end
  end

  describe '#show_promotions?' do
    context 'without a user' do
      subject { helper.show_promotions?(nil) }

      it { is_expected.to eq(false) }
    end

    context 'with a user' do
      let_it_be(:selected_user) { create(:user) }

      subject { helper.show_promotions?(selected_user) }

      context 'on saas' do
        before do
          stub_ee_application_setting(should_check_namespace_plan: true)
        end

        it { is_expected.to eq(true) }
      end

      context 'when gitlabdotcom returns false' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false)
        end

        it { is_expected.to eq(false) }
      end

      context 'on EE' do
        context 'with hide on self managed true' do
          subject { helper.show_promotions?(selected_user, hide_on_self_managed: true) }

          it { is_expected.to eq(false) }
        end

        context 'without a valid license' do
          before do
            allow(License).to receive(:current).and_return(nil)
          end

          it { is_expected.to eq(true) }
        end

        context 'with a valid license' do
          let_it_be(:license) { create(:license) }

          before do
            allow(License).to receive(:current).and_return(license)
          end

          context 'expired license' do
            before do
              allow(license).to receive(:expired?).and_return(true)
            end

            it { is_expected.to eq(true) }
          end

          context 'non expired license' do
            before do
              allow(license).to receive(:expired?).and_return(false)
            end

            it { is_expected.to eq(false) }
          end
        end
      end
    end
  end
end
