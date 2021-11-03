import { GlBanner, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SubscriptionActivationBanner, {
  ACTIVATE_SUBSCRIPTION_EVENT,
  CLOSE_ACTIVATE_SUBSCRIPTION_BANNER_EVENT,
} from 'ee/admin/subscriptions/show/components/subscription_activation_banner.vue';
import {
  activateCloudLicense,
  subscriptionBannerBlogPostUrl,
  subscriptionBannerText,
  subscriptionBannerTitle,
} from 'ee/admin/subscriptions/show/constants';

describe('SubscriptionActivationBanner', () => {
  let wrapper;

  const findBanner = () => wrapper.findComponent(GlBanner);
  const findLink = (at) => wrapper.findAllComponents(GlLink).at(at);

  const customersPortalUrl = 'customers.dot';
  const congratulationSvgPath = '/path/to/svg';
  const createComponent = () => {
    wrapper = shallowMount(SubscriptionActivationBanner, {
      provide: {
        congratulationSvgPath,
        customersPortalUrl,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('provides the correct props to the banner', () => {
    expect(findBanner().props()).toMatchObject({
      buttonText: activateCloudLicense,
      title: subscriptionBannerTitle,
      svgPath: congratulationSvgPath,
    });
  });

  it('contains help text', () => {
    expect(findBanner().text()).toMatchInterpolatedText(subscriptionBannerText);
  });

  it('contains a link to the blog post', () => {
    expect(findLink(0).attributes('href')).toBe(subscriptionBannerBlogPostUrl);
  });

  it('contains a link to the customers portal', () => {
    expect(findLink(1).attributes('href')).toBe(customersPortalUrl);
  });

  it('emits an event when the primary button is clicked', () => {
    expect(wrapper.emitted(ACTIVATE_SUBSCRIPTION_EVENT)).toBeUndefined();

    findBanner().vm.$emit('primary');

    expect(wrapper.emitted(ACTIVATE_SUBSCRIPTION_EVENT)).toHaveLength(1);
  });

  it('emits an event when the close button is clicked', () => {
    expect(wrapper.emitted(CLOSE_ACTIVATE_SUBSCRIPTION_BANNER_EVENT)).toBeUndefined();

    findBanner().vm.$emit('close');

    expect(wrapper.emitted(CLOSE_ACTIVATE_SUBSCRIPTION_BANNER_EVENT)).toHaveLength(1);
  });
});
