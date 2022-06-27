import * as Sentry from '@sentry/browser';
import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import ProtectedEnvironmentEdit from './protected_environment_edit.vue';

Vue.use(GlToast);

export const initProtectedEnvironmentEditList = () => {
  const parentContainer = document.querySelector('.js-protected-environments-list');
  const envEditFormEls = parentContainer?.querySelectorAll('.js-protected-environment-edit-form');

  if (envEditFormEls?.length) {
    envEditFormEls.forEach((el) => {
      const {
        url,
        label,
        disabled,
        preselectedItems,
        requiredApprovalCount,
        environmentName,
        environmentLink,
        deleteProtectedEnvironmentLink,
      } = el.dataset;

      let preselected = [];
      try {
        preselected = JSON.parse(preselectedItems);
      } catch (e) {
        Sentry.captureException(e);
      }
      return new Vue({
        el,
        render(createElement) {
          return createElement(ProtectedEnvironmentEdit, {
            props: {
              parentContainer,
              preselectedItems: preselected,
              url,
              label,
              disabled,
              requiredApprovalCount: parseInt(requiredApprovalCount, 10),
              environmentName,
              environmentLink,
              deleteProtectedEnvironmentLink,
            },
          });
        },
      });
    });
  }
};
