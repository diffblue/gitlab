import 'bootstrap';
import htmlGroupSamlProvidersShow from 'test_fixtures/groups/saml_providers/show.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import SamlSettingsForm from 'ee/saml_providers/saml_settings_form';

describe('SamlSettingsForm', () => {
  let samlSettingsForm;
  beforeEach(() => {
    setHTMLFixture(htmlGroupSamlProvidersShow);
    samlSettingsForm = new SamlSettingsForm('#js-saml-settings-form');
    samlSettingsForm.init();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const findGroupSamlSetting = () => samlSettingsForm.settings.find((s) => s.name === 'group-saml');
  const findEnforcedSsoSetting = () =>
    samlSettingsForm.settings.find((s) => s.name === 'enforced-sso');
  const findEnforcedGitActivity = () =>
    samlSettingsForm.settings.find((s) => s.name === 'enforced-git-activity-check');

  const fireChangeEvent = (setting) => {
    setting.el.dispatchEvent(
      new Event('change', {
        bubbles: true,
      }),
    );
  };

  const checkSetting = (setting) => {
    // eslint-disable-next-line no-param-reassign
    setting.el.checked = true;

    fireChangeEvent(setting);
  };

  const uncheckSetting = (setting) => {
    // eslint-disable-next-line no-param-reassign
    setting.el.checked = false;

    fireChangeEvent(setting);
  };

  const expectTestButtonDisabled = () => {
    expect(samlSettingsForm.testButtonDisabled.classList.contains('gl-display-none')).toBe(false);
    expect(samlSettingsForm.testButton.classList.contains('gl-display-none')).toBe(true);
  };
  const expectTestButtonEnabled = () => {
    expect(samlSettingsForm.testButtonDisabled.classList.contains('gl-display-none')).toBe(true);
    expect(samlSettingsForm.testButton.classList.contains('gl-display-none')).toBe(false);
  };

  describe('updateView', () => {
    it('disables Test button when form has changes and re-enables when returned to starting state', () => {
      expectTestButtonEnabled();

      uncheckSetting(findEnforcedSsoSetting());

      expectTestButtonDisabled();

      checkSetting(findEnforcedSsoSetting());

      expectTestButtonEnabled();
    });

    it('keeps Test button disabled when SAML disabled for the group', () => {
      expectTestButtonEnabled();

      uncheckSetting(findGroupSamlSetting());

      expectTestButtonDisabled();
    });
  });

  it('correctly disables dependent toggle and shows helper text', () => {
    expect(findEnforcedSsoSetting().el.hasAttribute('disabled')).toBe(false);
    expect(findEnforcedSsoSetting().helperText.classList.contains('gl-display-none')).toBe(true);

    uncheckSetting(findGroupSamlSetting());

    expect(findEnforcedSsoSetting().el.hasAttribute('disabled')).toBe(true);
    expect(findEnforcedSsoSetting().helperText.classList.contains('gl-display-none')).toBe(false);
    expect(findEnforcedSsoSetting().value).toBe(true);
  });

  it('correctly shows warning text when checkbox is unchecked', () => {
    expect(findEnforcedSsoSetting().warning.classList.contains('gl-display-none')).toBe(true);

    uncheckSetting(findEnforcedSsoSetting());

    expect(findEnforcedSsoSetting().warning.classList.contains('gl-display-none')).toBe(false);
  });

  it('correctly disables multiple dependent toggles', () => {
    expect(findEnforcedSsoSetting().el.hasAttribute('disabled')).toBe(false);
    expect(findEnforcedGitActivity().el.hasAttribute('disabled')).toBe(false);

    uncheckSetting(findGroupSamlSetting());

    expect(findEnforcedSsoSetting().el.hasAttribute('disabled')).toBe(true);
    expect(findEnforcedGitActivity().el.hasAttribute('disabled')).toBe(true);
  });
});
