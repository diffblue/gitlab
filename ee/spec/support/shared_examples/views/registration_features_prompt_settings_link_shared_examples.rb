# frozen_string_literal: true

RSpec.shared_examples 'renders registration features settings link' do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  context 'as regular user' do
    before do
      allow(view).to receive(:current_user) { user }
    end

    it 'does not render settings link', :aggregate_failures do
      expect(rendered).not_to have_link(s_('RegistrationFeatures|Enable Service Ping and register for this feature.'))
    end
  end

  context 'as admin' do
    before do
      allow(view).to receive(:current_user) { admin }
    end

    it 'renders settings link', :aggregate_failures do
      render

      expect(rendered).to have_link(s_('RegistrationFeatures|Enable Service Ping and register for this feature.'))
    end
  end
end
