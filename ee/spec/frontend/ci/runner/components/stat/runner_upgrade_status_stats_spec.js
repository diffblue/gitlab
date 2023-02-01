import { shallowMount } from '@vue/test-utils';
import { GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';
import RunnerUpgradeStatusStats from 'ee_component/ci/runner/components/stat/runner_upgrade_status_stats.vue';
import RunnerSingleStat from '~/ci/runner/components/stat/runner_single_stat.vue';
import { INSTANCE_TYPE } from '~/ci/runner/constants';
import { UPGRADE_STATUS_AVAILABLE, UPGRADE_STATUS_RECOMMENDED } from 'ee/ci/runner/constants';

describe('RunnerStats', () => {
  let wrapper;

  const findRunnerSingleStatAt = (i) => wrapper.findAllComponents(RunnerSingleStat).at(i);
  const findPopoverByTarget = (target) =>
    wrapper.findAllComponents(GlPopover).filter((w) => w.attributes('target') === target);

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

  describe.each`
    glFeatures
    ${{ runnerUpgradeManagement: true }}
    ${{ runnerUpgradeManagementForNamespace: true }}
  `('With licensed feature $glFeatures', ({ glFeatures }) => {
    const statOptions = [
      {
        index: 0,
        title: s__('Runners|Upgrade available'),
        variant: 'info',
        variables: { upgradeStatus: UPGRADE_STATUS_AVAILABLE },
      },
      {
        index: 1,
        title: s__('Runners|Upgrade recommended'),
        variant: 'warning',
        variables: { upgradeStatus: UPGRADE_STATUS_RECOMMENDED },
      },
    ];

    describe('Renders upgrade stats', () => {
      beforeEach(() => {
        createComponent({
          glFeatures,
        });
      });

      it.each(statOptions)(
        'Passes attributes and popover details to "$title" stat',
        ({ index, title, variant, variables }) => {
          const stat = findRunnerSingleStatAt(index);

          expect(stat.props()).toEqual({
            scope: INSTANCE_TYPE,
            skip: false,
            variables,
          });
          expect(stat.attributes()).toMatchObject({
            'meta-icon': 'upgrade',
            title,
            variant,
          });

          const id = stat.attributes('id');
          expect(findPopoverByTarget(id).exists()).toBe(true);
        },
      );
    });

    it.each(statOptions)('Passes filters vars to "$title" stat', ({ index, variables }) => {
      createComponent({
        props: {
          variables: { paused: true },
        },
        glFeatures,
      });

      expect(findRunnerSingleStatAt(index).props('variables')).toEqual({
        paused: true,
        ...variables,
      });
    });

    it('Skips query for other stats', () => {
      createComponent({
        props: {
          variables: { upgradeStatus: UPGRADE_STATUS_AVAILABLE },
        },
        glFeatures,
      });

      expect(findRunnerSingleStatAt(0).props('skip')).toBe(false);
      expect(findRunnerSingleStatAt(1).props('skip')).toBe(true);
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
