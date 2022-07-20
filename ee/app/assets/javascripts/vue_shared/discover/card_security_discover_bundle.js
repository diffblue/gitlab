import Vue from 'vue';
import { s__ } from '~/locale';
import SecurityDiscoverApp from 'ee/vue_shared/discover/card_security_discover_app.vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';
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
    namespaceId,
    userName,
    firstName,
    lastName,
    companyName,
    glmContent,
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
    apolloProvider,
    components: {
      SecurityDiscoverApp,
    },
    provide: {
      small: false,
      user: {
        namespaceId,
        userName,
        firstName,
        lastName,
        companyName,
        glmContent,
      },
      ctaTracking: {
        action: 'click_button',
        label: s__('PQL|Contact sales'),
        experiment: 'pql_three_cta_test',
      },
    },
    render(createElement) {
      return createElement('security-discover-app', {
        props,
      });
    },
  });
};
