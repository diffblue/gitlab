import Vue from 'vue';
import SecurityDiscoverApp from 'ee/vue_shared/discover/card_security_discover_app.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default () => {
  const securityTab = document.getElementById('js-security-discover-app');
  if (!securityTab) {
    return null;
  }

  const {
    groupId,
    groupName,
    projectId,
    projectName,
    projectPersonal,
    linkMain,
    linkSecondary,
  } = securityTab.dataset;

  const props = {
    project: {
      id: projectId,
      name: projectName,
      isPersonal: parseBoolean(projectPersonal),
    },
    group: {
      id: groupId,
      name: groupName,
    },
    linkMain,
    linkSecondary,
  };

  return new Vue({
    el: securityTab,
    name: 'SecurityDiscoverRoot',
    components: {
      SecurityDiscoverApp,
    },
    render(createElement) {
      return createElement('security-discover-app', {
        props,
      });
    },
  });
};
