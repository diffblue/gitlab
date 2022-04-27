import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProjectManager from './components/instance/project_manager.vue';
import apolloProvider from './graphql/provider';

export default (el) => {
  if (!el) {
    return null;
  }

  const { isAuditor } = el.dataset;

  return new Vue({
    el,
    name: 'SecurityDashboardSettingsRoot',
    apolloProvider,
    render(createElement) {
      return createElement(ProjectManager, {
        props: {
          isAuditor: parseBoolean(isAuditor),
        },
      });
    },
  });
};
