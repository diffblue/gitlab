import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AutoFixUserCallout from 'ee/security_dashboard/components/shared/auto_fix_user_callout.vue';

describe('AutoFixUserCallout', () => {
  let wrapper;

  const helpPagePath = '/help/page/path';

  const createWrapper = () => {
    wrapper = shallowMount(AutoFixUserCallout, {
      propsData: {
        helpPagePath,
      },
    });
  };

  it('renders properly', () => {
    createWrapper();

    expect(wrapper.findComponent(GlBanner).exists()).toBe(true);
    expect(wrapper.findComponent(GlBanner).props()).toMatchObject({
      title: 'Introducing GitLab auto-fix',
      buttonText: 'Learn more',
      buttonLink: helpPagePath,
    });
    expect(wrapper.text()).toContain(
      "If you're using dependency and/or container scanning, and auto-fix is enabled, auto-fix automatically creates merge requests with fixes to vulnerabilities.",
    );
  });
});
