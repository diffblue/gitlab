import { shallowMount } from '@vue/test-utils';
import RunnerStatusCell from '~/ci/runner/components/cells/runner_status_cell.vue';
import waitForPromises from 'helpers/wait_for_promises';

import RunnerUpgradeStatusBadge from 'ee/ci/runner/components/runner_upgrade_status_badge.vue';
import { UPGRADE_STATUS_AVAILABLE } from 'ee/ci/runner/constants';

describe('RunnerStatusCell', () => {
  let wrapper;

  const findUpgradeStatusBadge = () => wrapper.findComponent(RunnerUpgradeStatusBadge);

  const createComponent = ({ runner = {} } = {}) => {
    wrapper = shallowMount(RunnerStatusCell, {
      propsData: {
        runner: {
          upgradeStatus: UPGRADE_STATUS_AVAILABLE,
          ...runner,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays upgrade status', async () => {
    createComponent();

    await waitForPromises();

    expect(findUpgradeStatusBadge().props('runner')).toEqual(
      expect.objectContaining({ upgradeStatus: UPGRADE_STATUS_AVAILABLE }),
    );
  });
});
