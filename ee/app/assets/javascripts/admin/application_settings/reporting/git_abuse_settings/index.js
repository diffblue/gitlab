import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import { parseFormProps } from './utils';
import SettingsFormContainer from './components/settings_form_container.vue';

Vue.use(VueApollo);

export const initGitAbuseRateLimitSettingsForm = () => {
  const el = document.getElementById('js-git-abuse-rate-limit-settings-form');

  if (!el) {
    return false;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    maxNumberOfRepositoryDownloads,
    maxNumberOfRepositoryDownloadsWithinTimePeriod,
    gitRateLimitUsersAllowlist,
    gitRateLimitUsersAlertlist,
    autoBanUserOnExcessiveProjectsDownload,
  } = parseFormProps(el.dataset);

  return new Vue({
    el,
    apolloProvider,
    name: 'GitAbuseRateLimitSettingsFormRoot',
    render: (createElement) =>
      createElement(SettingsFormContainer, {
        props: {
          maxDownloads: maxNumberOfRepositoryDownloads,
          timePeriod: maxNumberOfRepositoryDownloadsWithinTimePeriod,
          allowlist: gitRateLimitUsersAllowlist,
          alertlist: gitRateLimitUsersAlertlist,
          autoBanUsers: autoBanUserOnExcessiveProjectsDownload,
        },
      }),
  });
};
