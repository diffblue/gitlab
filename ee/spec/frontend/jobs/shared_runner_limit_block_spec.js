import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SharedRunnerLimitBlock from 'ee/jobs/components/shared_runner_limit_block.vue';
import { trimText } from 'helpers/text_helper';

describe('Shared Runner Limit Block', () => {
  let wrapper;

  const projectPath = 'h5bp/html5-boilerplate';
  const subscriptionsMoreMinutesUrl = 'https://customers.gitlab.com/buy_pipeline_minutes';

  const factory = (options = {}) => {
    wrapper = shallowMount(SharedRunnerLimitBlock, {
      ...options,
    });
  };

  describe('quota information', () => {
    beforeEach(() => {
      factory({
        propsData: {
          quotaUsed: 1000,
          quotaLimit: 4000,
          projectPath,
          subscriptionsMoreMinutesUrl,
        },
      });
    });

    it('renders provided quota limit and used quota', () => {
      expect(wrapper.text()).toContain(
        'You have used 1000 out of 4000 of your shared Runners pipeline minutes',
      );
    });

    it('renders call to action gl-button with the right href', () => {
      const glButton = wrapper.findComponent(GlButton);

      expect(glButton.isVisible()).toBe(true);
      expect(glButton.attributes('variant')).toBe('danger');
      expect(glButton.attributes('href')).toBe(subscriptionsMoreMinutesUrl);
    });
  });

  describe('with runnersPath', () => {
    it('renders runner link', () => {
      factory({
        propsData: {
          quotaUsed: 1000,
          quotaLimit: 4000,
          projectPath,
          subscriptionsMoreMinutesUrl,
        },
      });

      expect(trimText(wrapper.text())).toContain('For more information, go to the Runners page.');
    });
  });
});
