import { shallowMount } from '@vue/test-utils';
import CardSecurityShowcaseApp from 'ee/vue_shared/showcase/card_security_showcase_app.vue';

describe('Card Security Showcase App', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMount(CardSecurityShowcaseApp, {
      provide: {
        billingVulnerabilityManagement: '/billing?g=1',
        billingDependencyScanning: '/billing?g=2',
        billingDast: '/billing?g=3',
        billingContainerScanning: '/billing?g=4',
        trialVulnerabilityManagement: '/trial?g=1',
        trialDependencyScanning: '/trial?g=2',
        trialDast: '/trial?g=3',
        trialContainerScanning: '/trial?g=4',
      },
    });
  };

  it('renders correctly', () => {
    createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });
});
