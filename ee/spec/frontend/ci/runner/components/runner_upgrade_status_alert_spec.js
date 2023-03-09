import { GlAlert, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { s__ } from '~/locale';

import RunnerUpgradeStatusAlert from 'ee/ci/runner/components/runner_upgrade_status_alert.vue';
import {
  UPGRADE_STATUS_AVAILABLE,
  UPGRADE_STATUS_RECOMMENDED,
  UPGRADE_STATUS_NOT_AVAILABLE,
  RUNNER_INSTALL_HELP_PATH,
  RUNNER_VERSION_HELP_PATH,
} from 'ee/ci/runner/constants';

describe('RunnerUpgradeStatusAlert', () => {
  let wrapper;
  let glFeatures;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLinks = () => wrapper.findAllComponents(GlLink).wrappers;

  const createComponent = ({ runner = {} } = {}) => {
    wrapper = mount(RunnerUpgradeStatusAlert, {
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

  describe('When no feature is enabled', () => {
    beforeEach(() => {
      glFeatures = {};
    });

    it('Displays no upgrade status', () => {
      createComponent();

      expect(findAlert().exists()).toBe(false);
    });
  });

  describe.each([['runnerUpgradeManagement'], ['runnerUpgradeManagementForNamespace']])(
    'When feature "%s" is enabled',
    (feature) => {
      beforeEach(() => {
        glFeatures[feature] = true;
      });

      it('Displays runner links', () => {
        createComponent({
          runner: {
            upgradeStatus: UPGRADE_STATUS_AVAILABLE,
          },
        });

        const hrefs = findLinks().map((w) => w.attributes('href'));
        expect(hrefs.sort()).toEqual([RUNNER_INSTALL_HELP_PATH, RUNNER_VERSION_HELP_PATH].sort());
      });

      it('Displays upgrade available status', () => {
        createComponent({
          runner: {
            upgradeStatus: UPGRADE_STATUS_AVAILABLE,
          },
        });

        expect(findAlert().props('title')).toBe(s__('Runners|Upgrade available'));
        expect(findAlert().props('variant')).toBe('info');
      });

      it('Displays upgrade recommended status', () => {
        createComponent({
          runner: {
            upgradeStatus: UPGRADE_STATUS_RECOMMENDED,
          },
        });

        expect(findAlert().props()).toMatchObject({
          title: s__('Runners|Upgrade recommended'),
          variant: 'warning',
        });
      });

      it('Displays no upgrade status', () => {
        createComponent({
          runner: {
            upgradeStatus: UPGRADE_STATUS_NOT_AVAILABLE,
          },
        });

        expect(findAlert().exists()).toBe(false);
      });
    },
  );
});
