import SamlSettingsForm from 'ee/saml_providers/saml_settings_form';

export default function initSAML() {
  new SamlSettingsForm('#js-saml-settings-form').init();
}
