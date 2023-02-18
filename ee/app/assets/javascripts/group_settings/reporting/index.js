import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import { parseFormProps } from 'ee_component/admin/application_settings/reporting/git_abuse_settings/utils';
import SettingsFormContainer from './components/settings_form_container.vue';

Vue.use(VueApollo);

export const initSettingsForm = () => {
  const el = document.getElementById('js-unique-project-download-limit-settings-form');

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

  const { groupFullPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    name: 'SettingsFormApp',
    provide: { groupFullPath },
    render: (createElement) =>
      createElement(SettingsFormContainer, {
        props: {
          groupFullPath,
          maxDownloads: maxNumberOfRepositoryDownloads,
          timePeriod: maxNumberOfRepositoryDownloadsWithinTimePeriod,
          allowlist: gitRateLimitUsersAllowlist,
          alertlist: gitRateLimitUsersAlertlist,
          autoBanUsers: autoBanUserOnExcessiveProjectsDownload,
        },
      }),
  });
};
