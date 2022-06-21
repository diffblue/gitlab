import Vue from 'vue';
import SecurityShowcaseApp from 'ee/vue_shared/showcase/card_security_showcase_app.vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';

export default () => {
  const securityTab = document.getElementById('js-security-showcase-app');
  if (!securityTab) {
    return null;
  }

  const {
    billingVulnerabilityManagement,
    billingDependencyScanning,
    billingDast,
    billingContainerScanning,
    trialVulnerabilityManagement,
    trialDependencyScanning,
    trialDast,
    trialContainerScanning,
  } = securityTab.dataset;

  return new Vue({
    el: securityTab,
    name: 'SecurityShowcaseRoot',
    apolloProvider,
    components: {
      SecurityShowcaseApp,
    },
    provide: {
      billingVulnerabilityManagement,
      billingDependencyScanning,
      billingDast,
      billingContainerScanning,
      trialVulnerabilityManagement,
      trialDependencyScanning,
      trialDast,
      trialContainerScanning,
    },
    render(createElement) {
      return createElement('security-showcase-app');
    },
  });
};
