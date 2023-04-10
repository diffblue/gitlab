# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/edit.html.haml', feature_category: :subgroups do
  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }

  before do
    group.add_owner(user)

    assign(:group, group)
    allow(view).to receive(:current_user) { user }
    allow(view).to receive(:ai_assist_ui_enabled?)
  end

  context 'ip_restriction' do
    shared_examples_for 'renders ip_restriction setting' do
      it 'renders ranges in comma separated format' do
        render

        expect(rendered).to render_template('groups/settings/_ip_restriction')
        expect(rendered).to(have_field(
          'group_ip_restriction_ranges', disabled: false, with: ranges.join(","), type: :hidden
        ))
      end
    end

    shared_examples_for 'does not render ip_restriction setting' do
      it 'does not render the ranges' do
        render

        expect(rendered).to render_template('groups/settings/_ip_restriction')
        expect(rendered).not_to have_field('group_ip_restriction_ranges', type: :hidden)
      end
    end

    context 'feature is enabled' do
      before do
        stub_licensed_features(group_ip_restriction: true)
      end

      context 'top-level group' do
        before do
          ranges.each do |range|
            create(:ip_restriction, group: group, range: range)
          end
        end

        context 'with single subnet' do
          let(:ranges) { ['192.168.0.0/24'] }

          it_behaves_like 'renders ip_restriction setting'
          it_behaves_like 'does not render registration features prompt'
        end

        context 'with multiple subnets' do
          let(:ranges) { ['192.168.0.0/24', '192.168.1.0/8'] }

          it_behaves_like 'renders ip_restriction setting'
          it_behaves_like 'does not render registration features prompt'
        end
      end
    end

    context 'subgroup' do
      let(:group) { create(:group, :nested) }

      it_behaves_like 'does not render ip_restriction setting'
    end

    context 'feature is disabled' do
      before do
        stub_licensed_features(group_ip_restriction: false)
      end

      it_behaves_like 'does not render ip_restriction setting'
    end

    context 'prompt user about registration features' do
      context 'with service ping disabled' do
        before do
          stub_application_setting(usage_ping_enabled: false)
        end

        context 'with no license' do
          before do
            allow(License).to receive(:current).and_return(nil)
          end

          it_behaves_like 'renders registration features prompt', :group_disabled_ip_restriction_ranges
          it_behaves_like 'renders registration features settings link'
        end

        context 'with a valid license' do
          before do
            license = build(:license)
            allow(License).to receive(:current).and_return(license)
          end

          it_behaves_like 'does not render registration features prompt', :group_disabled_ip_restriction_ranges
        end
      end

      context 'with service ping enabled' do
        before do
          stub_application_setting(usage_ping_enabled: true)
        end

        it_behaves_like 'does not render registration features prompt', :group_disabled_ip_restriction_ranges
      end
    end
  end

  context 'allowed_email_domain' do
    shared_examples_for 'renders allowed_email_domain setting' do
      it 'renders domains in comma separated format' do
        render

        expect(rendered).to render_template('groups/settings/_allowed_email_domain')
        expect(rendered).to(have_field(
          'group_allowed_email_domains_list', disabled: false, with: domains.join(","), type: :hidden
        ))
      end
    end

    shared_examples_for 'does not render allowed_email_domain setting' do
      it 'does not render the domains' do
        render

        expect(rendered).to render_template('groups/settings/_allowed_email_domain')
        expect(rendered).not_to have_field('group_allowed_email_domains_list')
      end
    end

    context 'feature is enabled' do
      before do
        allow(group).to receive(:licensed_feature_available?).and_return(false)
        allow(group).to receive(:licensed_feature_available?).with(:group_allowed_email_domains).and_return(true)
      end

      context 'top-level group' do
        before do
          domains.each do |domain|
            create(:allowed_email_domain, group: group, domain: domain)
          end
        end

        context 'with single domain' do
          let(:domains) { ['acme.com'] }

          it_behaves_like 'renders allowed_email_domain setting'
        end

        context 'with multiple domain' do
          let(:domains) { ['acme.com', 'twitter.com'] }

          it_behaves_like 'renders allowed_email_domain setting'
        end
      end

      context 'subgroup' do
        let(:group) { create(:group, :nested) }

        it_behaves_like 'does not render allowed_email_domain setting'
      end
    end

    context 'feature is disabled' do
      it_behaves_like 'does not render allowed_email_domain setting'
    end
  end
end
