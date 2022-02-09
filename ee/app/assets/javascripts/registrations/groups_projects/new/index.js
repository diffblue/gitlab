import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import $ from 'jquery';
import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import { bindHowToImport } from '~/projects/project_new';
import { displayGroupPath, displayProjectPath } from './path_display';
import showTooltip from './show_tooltip';
import CreditCardVerification from './components/credit_card_verification.vue';
import ExitLink from './components/exit_link.vue';

const importButtonsSubmit = () => {
  const buttons = document.querySelectorAll('.js-import-project-buttons a');
  const form = document.querySelector('.js-import-project-form');
  const submit = form.querySelector('input[type="submit"]');
  const importUrlField = form.querySelector('.js-import-url');

  const clickHandler = (e) => {
    e.preventDefault();
    importUrlField.value = e.target.getAttribute('href');
    submit.click();
  };

  buttons.forEach((button) => button.addEventListener('click', clickHandler));
};

const setAutofocus = () => {
  const setInputfocus = () => {
    document
      .querySelector('.js-group-project-tab-contents .tab-pane.active .js-group-name-field')
      ?.focus();
  };

  setInputfocus();

  $('.js-group-project-tabs').on('shown.bs.tab', setInputfocus);
};

const mobileTooltipOpts = () => (bp.getBreakpointSize() === 'xs' ? { placement: 'bottom' } : {});

const mountVerification = () => {
  const el = document.querySelector('.js-credit-card-verification');

  if (!el) {
    return null;
  }

  const { completed, iframeUrl, allowedOrigin } = el.dataset;

  return new Vue({
    el,
    provide: {
      completed: parseBoolean(completed),
      iframeUrl,
      allowedOrigin,
    },
    render(createElement) {
      return createElement(CreditCardVerification);
    },
  });
};

const mountExitLink = () => {
  const el = document.querySelector('.js-exit-registration-verification');

  if (!el) {
    return null;
  }

  const { exitPath } = el.dataset;

  return new Vue({
    el,
    provide: {
      exitPath,
    },
    render(createElement) {
      return createElement(ExitLink);
    },
  });
};

export default () => {
  displayGroupPath('.js-group-path-source', '.js-group-path-display');
  displayGroupPath('.js-import-group-path-source', '.js-import-group-path-display');
  displayProjectPath('.js-project-path-source', '.js-project-path-display');
  showTooltip('.js-group-name-tooltip', mobileTooltipOpts());
  importButtonsSubmit();
  bindHowToImport();
  setAutofocus();
  mountVerification();
  mountExitLink();
};
