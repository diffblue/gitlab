# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/usage_quotas/index' do
  let_it_be(:group) { create(:group) }

  before do
    assign(:group, group)
  end

  context 'when free plan limit preview is present' do
    it 'renders the alert partial and calls the alert class' do
      expect(Namespaces::FreeUserCap::PreviewUsageQuotaAlertComponent).to receive(:new).and_call_original

      render

      expect(rendered).to render_template('groups/usage_quotas/_free_user_cap_alert')
    end
  end
end
