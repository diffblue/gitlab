import $ from 'jquery';
import dirtySubmitFactory from '~/dirty_submit/dirty_submit_factory';
import { __ } from '~/locale';
import { fixTitle } from '~/tooltips';

const CALLOUT_SELECTOR = '.js-callout';
const HELPER_SELECTOR = '.js-helper-text';
const WARNING_SELECTOR = '.js-warning';

function getHelperText(el) {
  return el?.parentNode?.querySelector(HELPER_SELECTOR) || null;
}

function getWarning(el) {
  return el?.parentNode?.querySelector(WARNING_SELECTOR) || null;
}

function getCallout(el) {
  return el?.closest('.form-group')?.querySelector(CALLOUT_SELECTOR) || null;
}

function toggleElementVisibility(el, show) {
  if (show) {
    el?.classList.remove('gl-display-none');
  } else {
    el?.classList.add('gl-display-none');
  }
}

export default class SamlSettingsForm {
  constructor(formSelector) {
    this.form = document.querySelector(formSelector);
    this.settings = [
      {
        name: 'group-saml',
        el: this.form.querySelector('.js-group-saml-enabled-input'),
      },
      {
        name: 'enforced-sso',
        el: this.form.querySelector('.js-group-saml-enforced-sso-input'),
        dependsOn: 'group-saml',
      },
      {
        name: 'enforced-group-managed-accounts',
        el: this.form.querySelector('.js-group-saml-enforced-group-managed-accounts-input'),
        dependsOn: 'enforced-sso',
      },
      {
        name: 'enforced-git-activity-check',
        el: this.form.querySelector('.js-group-saml-enforced-git-check-input'),
        dependsOn: 'enforced-sso',
      },
      {
        name: 'prohibited-outer-forks',
        el: this.form.querySelector('.js-group-saml-prohibited-outer-forks-input'),
        dependsOn: 'enforced-group-managed-accounts',
      },
    ]
      .filter((s) => s.el)
      .map((setting) => ({
        ...setting,
        helperText: getHelperText(setting.el),
        warning: getWarning(setting.el),
        callout: getCallout(setting.el),
      }));

    this.testButtonTooltipWrapper = this.form.querySelector('#js-saml-test-button');
    this.testButton = this.testButtonTooltipWrapper.querySelector('a');
    this.testButtonDisabled = this.testButtonTooltipWrapper.querySelector('button[disabled]');
    this.dirtyFormChecker = dirtySubmitFactory(this.form);
    this.dirtyFormChecker.addInputsListener(this.handleInputsChange);
  }

  findSetting(name) {
    return this.settings.find((s) => s.name === name);
  }

  settingIsDefined(el) {
    return this.settings.some((setting) => setting.el.isSameNode(el));
  }

  getValueWithDeps(name) {
    const setting = this.findSetting(name);
    let currentDependsOn = setting.dependsOn;

    while (currentDependsOn) {
      const { value, dependsOn } = this.findSetting(currentDependsOn);
      if (!value) {
        return false;
      }
      currentDependsOn = dependsOn;
    }

    return setting.value;
  }

  init() {
    this.dirtyFormChecker.init();
    this.updateSAMLSettings();
    this.updateView();
  }

  handleInputsChange = (event) => {
    if (this.settingIsDefined(event.target)) {
      this.updateSAMLSettings();
    }

    this.updateView();
  };

  isFormDirty() {
    return this.dirtyFormChecker.dirtyInputs.length;
  }

  updateSAMLSettings() {
    this.settings = this.settings.map((setting) => ({
      ...setting,
      value: setting.el.checked,
    }));
  }

  testButtonTooltip() {
    if (!this.getValueWithDeps('group-saml')) {
      return __('Group SAML must be enabled to test');
    }

    if (this.isFormDirty()) {
      return __('Save changes before testing');
    }

    return __('Redirect to SAML provider to test configuration');
  }

  disableTestButton() {
    toggleElementVisibility(this.testButton, false);
    toggleElementVisibility(this.testButtonDisabled, true);
  }

  enableTestButton() {
    toggleElementVisibility(this.testButton, true);
    toggleElementVisibility(this.testButtonDisabled, false);
  }

  updateCheckboxes() {
    this.settings
      .filter((setting) => setting.dependsOn)
      .forEach((setting) => {
        const { helperText, warning, callout, el } = setting;
        const isRelatedToggleOn = this.getValueWithDeps(setting.dependsOn);

        if (helperText) {
          toggleElementVisibility(helperText, !isRelatedToggleOn);
        }

        el.disabled = !isRelatedToggleOn;

        if (warning) {
          toggleElementVisibility(warning, !setting.value);
        }

        if (callout) {
          toggleElementVisibility(callout, setting.value && isRelatedToggleOn);
        }
      });
  }

  updateView() {
    if (this.getValueWithDeps('group-saml') && !this.isFormDirty()) {
      this.enableTestButton();
    } else {
      this.disableTestButton();
    }

    this.updateCheckboxes();

    // Update tooltip using wrapper so it works when input disabled
    this.testButtonTooltipWrapper.setAttribute('title', this.testButtonTooltip());

    fixTitle($(this.testButtonTooltipWrapper));
  }
}
