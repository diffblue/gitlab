import { shallowMount } from '@vue/test-utils';
import RunnerStats from '~/ci/runner/components/stat/runner_stats.vue';
import RunnerUpgradeStatusStats from 'ee_component/ci/runner/components/stat/runner_upgrade_status_stats.vue';
import RunnerPerformanceStat from 'ee_component/ci/runner/components/stat/runner_performance_stat.vue';
import { INSTANCE_TYPE } from '~/ci/runner/constants';
import waitForPromises from 'helpers/wait_for_promises';

describe('RunnerStats', () => {
  let wrapper;

  const findRunnerUpgradeStatusStats = () => wrapper.findComponent(RunnerUpgradeStatusStats);
  const findRunnerPerformanceStat = () => wrapper.findComponent(RunnerPerformanceStat);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerStats, {
      propsData: {
        scope: INSTANCE_TYPE,
        variables: {},
        ...props,
      },
      stubs: {
        RunnerCount: {
          render() {
            return this.$scopedSlots.default({
              count: 1, // at least one runner exists
            });
          },
        },
      },
    });
  };

  it('Displays upgrade status stats', async () => {
    createComponent({ props: { variables: { paused: true } } });

    await waitForPromises();

    expect(findRunnerUpgradeStatusStats().props('scope')).toBe(INSTANCE_TYPE);
    expect(findRunnerUpgradeStatusStats().props('variables').paused).toBe(true);
  });

  it('Displays job wait stats', async () => {
    createComponent();

    await waitForPromises();

    expect(findRunnerPerformanceStat().exists()).toBe(true);
  });
});
