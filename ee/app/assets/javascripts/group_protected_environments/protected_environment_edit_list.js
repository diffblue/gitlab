import * as Sentry from '@sentry/browser';
import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import ProtectedEnvironmentEdit from './protected_environment_edit.vue';

Vue.use(GlToast);

export const initProtectedEnvironmentEditList = () => {
  const parentContainer = document.querySelector('.js-protected-environments-list');
  const envEditFormEls = parentContainer.querySelectorAll('.js-protected-environment-edit-form');

  envEditFormEls.forEach((el) => {
    const accessDropdownEl = el.querySelector('.js-allowed-to-deploy');
    if (!accessDropdownEl) {
      return false;
    }

    const { url } = el.dataset;
    const { label, preselectedItems } = accessDropdownEl.dataset;

    let preselected = [];
    try {
      preselected = JSON.parse(preselectedItems);
    } catch (e) {
      Sentry.captureException(e);
    }
    return new Vue({
      el: accessDropdownEl,
      render(createElement) {
        return createElement(ProtectedEnvironmentEdit, {
          props: {
            parentContainer,
            preselectedItems: preselected,
            url,
            label,
          },
        });
      },
    });
  });
};
