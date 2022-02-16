import Vue from 'vue';
import SecurityDiscoverApp from 'ee/vue_shared/discover/card_security_discover_app.vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';

export default () => {
  const securityTab = document.getElementById('js-security-discover-app');
  const {
    groupId,
    groupName,
    projectId,
    projectName,
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
    },
    render(createElement) {
      return createElement('security-discover-app', {
        props,
      });
    },
  });
};
