import { GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import RunnerUpgradeStatusBadge from 'ee/runner/components/runner_upgrade_status_badge.vue';
import {
  UPGRADE_STATUS_AVAILABLE,
  UPGRADE_STATUS_RECOMMENDED,
  UPGRADE_STATUS_NOT_AVAILABLE,
} from 'ee/runner/constants';

describe('RunnerStatusCell', () => {
  let wrapper;
  let glFeatures;

  const findBadge = () => wrapper.findComponent(GlBadge);

  const createComponent = ({ runner = {} } = {}) => {
    wrapper = mount(RunnerUpgradeStatusBadge, {
      propsData: {
        runner: {
          upgradeStatus: UPGRADE_STATUS_AVAILABLE,
          ...runner,
        },
      },
      provide: {
        glFeatures,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

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
        createComponent({
          runner: {
            upgradeStatus: UPGRADE_STATUS_AVAILABLE,
          },
        });

        expect(findBadge().text()).toBe('upgrade available');
        expect(findBadge().props('variant')).toBe('info');
      });

      it('Displays upgrade recommended status', () => {
        createComponent({
          runner: {
            upgradeStatus: UPGRADE_STATUS_RECOMMENDED,
          },
        });

        expect(findBadge().text()).toBe('upgrade recommended');
        expect(findBadge().props('variant')).toBe('warning');
      });

      it('Displays no unavailable status', () => {
        createComponent({
          runner: {
            upgradeStatus: UPGRADE_STATUS_NOT_AVAILABLE,
          },
        });

        expect(findBadge().exists()).toBe(false);
      });

      it('Displays no status for unknown status', () => {
        createComponent({
          runner: {
            upgradeStatus: 'SOME_UNKNOWN_STATUS',
          },
        });

        expect(findBadge().exists()).toBe(false);
      });
    },
  );
});
