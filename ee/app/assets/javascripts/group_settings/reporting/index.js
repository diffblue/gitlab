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
  } = parseFormProps(el.dataset);

  const groupId = parseInt(el.dataset.groupId, 10);

  return new Vue({
    el,
    apolloProvider,
    name: 'SettingsFormApp',
    render: (createElement) =>
      createElement(SettingsFormContainer, {
        props: {
          groupId,
          maxDownloads: maxNumberOfRepositoryDownloads,
          timePeriod: maxNumberOfRepositoryDownloadsWithinTimePeriod,
          allowlist: gitRateLimitUsersAllowlist,
        },
      }),
  });
};
