import { shallowMount } from '@vue/test-utils';
import RunnerStats from '~/runner/components/stat/runner_stats.vue';
import RunnerUpgradeStatusStats from 'ee_component/runner/components/stat/runner_upgrade_status_stats.vue';
import { INSTANCE_TYPE } from '~/runner/constants';
import waitForPromises from 'helpers/wait_for_promises';

describe('RunnerStats', () => {
  let wrapper;

  const findRunnerUpgradeStatusStats = () => wrapper.findComponent(RunnerUpgradeStatusStats);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerStats, {
      propsData: {
        scope: INSTANCE_TYPE,
        variables: {},
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays upgrade status stats', async () => {
    createComponent({ props: { variables: { paused: true } } });

    await waitForPromises();

    expect(findRunnerUpgradeStatusStats().props('scope')).toBe('INSTANCE_TYPE');
    expect(findRunnerUpgradeStatusStats().props('variables').paused).toBe(true);
  });
});
