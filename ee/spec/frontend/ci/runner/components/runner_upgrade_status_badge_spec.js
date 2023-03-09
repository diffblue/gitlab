import { GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import RunnerUpgradeStatusBadge from 'ee/ci/runner/components/runner_upgrade_status_badge.vue';
import {
  UPGRADE_STATUS_AVAILABLE,
  UPGRADE_STATUS_RECOMMENDED,
  UPGRADE_STATUS_NOT_AVAILABLE,
  I18N_UPGRADE_STATUS_AVAILABLE,
  I18N_UPGRADE_STATUS_RECOMMENDED,
} from 'ee/ci/runner/constants';

describe('RunnerStatusCell', () => {
  let wrapper;
  let glFeatures;

  const findBadge = () => wrapper.findComponent(GlBadge);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mount(RunnerUpgradeStatusBadge, {
      propsData: {
        runner: {
          upgradeStatus: UPGRADE_STATUS_AVAILABLE,
          ...props.runner,
        },
        ...props,
      },
      provide: {
        glFeatures,
      },
    });
  };

  describe('When no feature is enabled', () => {
    beforeEach(() => {
      glFeatures = {};
    });

    it('Displays no upgrade status', () => {
      createComponent();

      expect(findBadge().exists()).toBe(false);
    });
  });

  describe.each([['runnerUpgradeManagement'], ['runnerUpgradeManagementForNamespace']])(
    'When feature "%s" is enabled',
    (feature) => {
      beforeEach(() => {
        glFeatures[feature] = true;
      });

      it('Displays upgrade available status', () => {
        createComponent();

        expect(findBadge().text()).toBe(I18N_UPGRADE_STATUS_AVAILABLE);
        expect(findBadge().props('icon')).toBe('upgrade');
        expect(findBadge().props('variant')).toBe('info');
      });

      it('Displays no icon when size is "sm"', () => {
        createComponent({ props: { size: 'sm' } });

        expect(findBadge().props('icon')).toBe(null);
      });

      it('Displays upgrade recommended status', () => {
        createComponent({
          props: {
            runner: {
              upgradeStatus: UPGRADE_STATUS_RECOMMENDED,
            },
          },
        });

        expect(findBadge().text()).toBe(I18N_UPGRADE_STATUS_RECOMMENDED);
        expect(findBadge().props('icon')).toBe('upgrade');
        expect(findBadge().props('variant')).toBe('warning');
      });

      it('Displays no unavailable status', () => {
        createComponent({
          props: {
            runner: {
              upgradeStatus: UPGRADE_STATUS_NOT_AVAILABLE,
            },
          },
        });

        expect(findBadge().exists()).toBe(false);
      });

      it('Displays no status for unknown status', () => {
        createComponent({
          props: {
            runner: {
              upgradeStatus: 'SOME_UNKNOWN_STATUS',
            },
          },
        });

        expect(findBadge().exists()).toBe(false);
      });
    },
  );
});
