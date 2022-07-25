import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  shallowMountExtended,
  mountExtended,
  extendedWrapper,
} from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { s__ } from '~/locale';

import { createLocalState } from '~/runner/graphql/list/local_state';
import AdminRunnersApp from '~/runner/admin_runners/admin_runners_app.vue';
import RunnerList from '~/runner/components/runner_list.vue';

import RunnerUpgradeStatusBadge from 'ee_component/runner/components/runner_upgrade_status_badge.vue';

import allRunnersQuery from 'ee_else_ce/runner/graphql/list/all_runners.query.graphql';
import allRunnersCountQuery from '~/runner/graphql/list/all_runners_count.query.graphql';

import {
  runnersCountData,
  onlineContactTimeoutSecs,
  staleTimeoutSecs,
  emptyStateSvgPath,
  emptyStateFilteredSvgPath,
} from 'jest/runner/mock_data';
import { allRunnersUpgradeStatusData } from '../mock_data';

const mockRegistrationToken = 'MOCK_REGISTRATION_TOKEN';

const mockRunnersHandler = jest.fn();
const mockRunnersCountHandler = jest.fn();

Vue.use(VueApollo);

describe('AdminRunnersApp', () => {
  let wrapper;
  let cacheConfig;
  let localMutations;

  const findRunnerRows = () => wrapper.findComponent(RunnerList).findAll('tr');

  const createComponent = ({
    props = {},
    mountFn = shallowMountExtended,
    provide,
    ...options
  } = {}) => {
    ({ cacheConfig, localMutations } = createLocalState());

    const handlers = [
      [allRunnersQuery, mockRunnersHandler],
      [allRunnersCountQuery, mockRunnersCountHandler],
    ];

    wrapper = mountFn(AdminRunnersApp, {
      apolloProvider: createMockApollo(handlers, {}, cacheConfig),
      propsData: {
        registrationToken: mockRegistrationToken,
        ...props,
      },
      provide: {
        localMutations,
        onlineContactTimeoutSecs,
        staleTimeoutSecs,
        emptyStateSvgPath,
        emptyStateFilteredSvgPath,
        ...provide,
      },
      ...options,
    });

    return waitForPromises();
  };

  beforeEach(() => {
    mockRunnersHandler.mockResolvedValue(allRunnersUpgradeStatusData);
    mockRunnersCountHandler.mockResolvedValue(runnersCountData);
  });

  afterEach(() => {
    mockRunnersHandler.mockReset();
    mockRunnersCountHandler.mockReset();
    wrapper.destroy();
  });

  it('shows upgrade badges', async () => {
    await createComponent({
      mountFn: mountExtended,
      provide: { glFeatures: { runnerUpgradeManagement: true } },
    });

    const rows = findRunnerRows().wrappers.map(extendedWrapper);

    expect(rows[1].findByText('15.1.1').exists()).toBe(true); // up to date
    expect(rows[1].find(RunnerUpgradeStatusBadge).text()).toBe('');

    expect(rows[2].findByText('15.1.0').exists()).toBe(true);
    expect(rows[2].find(RunnerUpgradeStatusBadge).text()).toBe(s__('Runners|upgrade recommended'));

    expect(rows[3].findByText('15.0.0').exists()).toBe(true);
    expect(rows[3].find(RunnerUpgradeStatusBadge).text()).toBe(s__('Runners|upgrade available'));
  });
});
