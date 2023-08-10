import { GlBadge, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerDashboardLink from 'ee_component/ci/runner/components/runner_dashboard_link.vue';

import { runnerDashboardPath } from 'ee_jest/ci/runner/mock_data';

describe('RunnerDashboardLink', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findButton = () => wrapper.findComponent(GlButton);

  const createComponent = (options) => {
    wrapper = shallowMountExtended(RunnerDashboardLink, {
      ...options,
    });
  };

  describe('when runnerDashboardPath is available', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          runnerDashboardPath,
        },
      });
    });

    it('renders button', () => {
      expect(findButton().text()).toContain(s__('Runners|Fleet dashboard'));
      expect(findButton().props('variant')).toBe('link');
      expect(findButton().attributes('href')).toBe(runnerDashboardPath);
    });

    it('renders badge', () => {
      expect(findBadge().props()).toMatchObject({ variant: 'info', size: 'sm' });
      expect(findBadge().text()).toContain(s__('Runners|New'));
    });
  });

  describe('when runnerDashboardPath is not available', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render', () => {
      expect(findButton().exists()).toBe(false);
    });
  });
});
