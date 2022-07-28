import { shallowMount } from '@vue/test-utils';
import { s__ } from '~/locale';
import RunnerUpgradeStatusStats from 'ee_component/runner/components/stat/runner_upgrade_status_stats.vue';
import RunnerSingleStat from '~/runner/components/stat/runner_single_stat.vue';
import { INSTANCE_TYPE } from '~/runner/constants';
import { UPGRADE_STATUS_AVAILABLE, UPGRADE_STATUS_RECOMMENDED } from 'ee/runner/constants';

describe('RunnerStats', () => {
  let wrapper;

  const findRunnerSingleStatAt = (i) => wrapper.findAllComponents(RunnerSingleStat).at(i);

  const createComponent = ({ props = {}, glFeatures = {}, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(RunnerUpgradeStatusStats, {
      propsData: {
        scope: INSTANCE_TYPE,
        variables: {},
        ...props,
      },
      provide: {
        glFeatures,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    glFeatures
    ${{ runnerUpgradeManagement: true }}
    ${{ runnerUpgradeManagementForNamespace: true }}
  `('With licensed feature $glFeatures', ({ glFeatures }) => {
    const statOptions = [
      {
        metatext: s__('Runners|recommended'),
        variant: 'warning',
        variables: { upgradeStatus: UPGRADE_STATUS_RECOMMENDED },
      },
      {
        metatext: s__('Runners|available'),
        variant: 'info',
        variables: { upgradeStatus: UPGRADE_STATUS_AVAILABLE },
      },
    ];

    it('Renders upgrade stats with correct scope and attributes', () => {
      createComponent({
        glFeatures,
      });

      statOptions.forEach(({ metatext, variant, variables }, i) => {
        const stat = findRunnerSingleStatAt(i);

        expect(stat.attributes()).toMatchObject({
          title: s__('Runners|Outdated'),
          metatext,
          variant,
        });
        expect(stat.props()).toEqual({
          scope: INSTANCE_TYPE,
          skip: false,
          variables,
        });
      });
    });

    it('Passes filter variables with a status filter', () => {
      createComponent({
        props: {
          variables: { paused: true },
        },
        glFeatures,
      });

      statOptions.forEach(({ variables }, i) => {
        expect(findRunnerSingleStatAt(i).props('variables')).toEqual({
          paused: true,
          ...variables,
        });
      });
    });

    it('Skips query for other stats', () => {
      createComponent({
        props: {
          variables: { upgradeStatus: UPGRADE_STATUS_AVAILABLE },
        },
        glFeatures,
      });

      expect(findRunnerSingleStatAt(0).props('skip')).toBe(true);
      expect(findRunnerSingleStatAt(1).props('skip')).toBe(false);
    });
  });

  describe('When no licensed features are available', () => {
    beforeEach(() => {
      createComponent({
        glFeatures: {},
      });
    });

    it('Does not render upgrade stats', () => {
      expect(wrapper.findComponent(RunnerSingleStat).exists()).toBe(false);
    });
  });
});
