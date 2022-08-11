import * as Sentry from '@sentry/browser';
import Vue from 'vue';
import GroupProtectedEnvironment from './group_protected_environment.vue';

export const initGroupProtectedEnvironmentList = () => {
  const envs = document.querySelectorAll('.js-group-protected-environment');

  envs.forEach((el) => {
    const { accessLevels: levels, project, environment } = el.dataset;

    try {
      const accessLevels = JSON.parse(levels);
      return new Vue({
        el,
        render(createElement) {
          return createElement(GroupProtectedEnvironment, {
            props: {
              accessLevels,
              environment,
              project,
            },
          });
        },
      });
    } catch (e) {
      Sentry.captureException(e);
    }

    return null;
  });
};
