# frozen_string_literal: true

RSpec.shared_examples 'does not render registration features prompt' do |disabled_field|
  it 'does not render a placeholder input with registration features message' do
    render

    if disabled_field
      expect(rendered).not_to have_field(disabled_field, disabled: true)
    end

    expect(rendered).not_to have_content(s_("RegistrationFeatures|Want to %{feature_title} for free?") % { feature_title: s_('RegistrationFeatures|use this feature') })
    expect(rendered).not_to have_link(s_('RegistrationFeatures|Enable Service Ping and register for this feature.'))
    expect(rendered).not_to have_link(s_('RegistrationFeatures|Registration Features Program'))
  end
end
