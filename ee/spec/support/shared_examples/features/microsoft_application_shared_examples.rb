# frozen_string_literal: true

RSpec.shared_examples_for 'Microsoft Azure integration form' do
  let(:tenant_id) { generate(:token) }
  let(:client_id) { generate(:token) }
  let(:client_secret) { generate(:token) }
  let(:login_endpoint) { 'https://login.microsoftonline.us' }
  let(:graph_endpoint) { 'https://graph.microsoft.us' }

  before do
    visit path
  end

  it 'displays the settings' do
    expect(page).to have_content(s_('Microsoft|Microsoft Azure Integration'))

    # Default values
    page.within('.microsoft-application') do
      expect(find_field(s_('Microsoft|Enable Microsoft Azure integration for this group'))).not_to be_checked
      expect(find_field(s_('Microsoft|Login API endpoint')).value)
        .to have_content('https://login.microsoftonline.com')
      expect(find_field(s_('Microsoft|Graph API endpoint')).value)
        .to have_content('https://graph.microsoft.com')
    end
  end

  it 'successfully saves' do
    page.within('.microsoft-application') do
      check s_('Microsoft|Enable Microsoft Azure integration for this group')
      fill_in s_('Microsoft|Tenant ID'), with: tenant_id
      fill_in s_('Microsoft|Client ID'), with: client_id
      fill_in s_('Microsoft|Client secret'), with: client_secret
      fill_in s_('Microsoft|Login API endpoint'), with: login_endpoint
      fill_in s_('Microsoft|Graph API endpoint'), with: graph_endpoint

      click_button(_("Save changes"))

      expect(find_field(s_('Microsoft|Enable Microsoft Azure integration for this group'))).to be_checked
      expect(find_field(s_('Microsoft|Tenant ID')).value).to have_content(tenant_id)
      expect(find_field(s_('Microsoft|Client ID')).value).to have_content(client_id)
      expect(find_field(s_('Microsoft|Login API endpoint')).value).to have_content(login_endpoint)
      expect(find_field(s_('Microsoft|Graph API endpoint')).value).to have_content(graph_endpoint)

      # Ensure the secret isn't displayed after save.
      expect(find_field(s_('Microsoft|Client secret')).value).not_to have_content(client_secret)
    end
  end

  it 'displays an error when fields are not filled' do
    page.within('.microsoft-application') do
      click_button(_("Save changes"))
    end

    expect(page).to have_content(
      "Tenant ID can't be blank, Client ID can't be blank, and Client secret can't be blank"
    )
  end
end
