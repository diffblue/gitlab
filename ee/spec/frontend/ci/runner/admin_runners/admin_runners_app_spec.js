import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createLocalState } from '~/ci/runner/graphql/list/local_state';
import AdminRunnersApp from '~/ci/runner/admin_runners/admin_runners_app.vue';
import RunnerList from '~/ci/runner/components/runner_list.vue';

import RunnerUpgradeStatusIcon from 'ee_component/ci/runner/components/runner_upgrade_status_icon.vue';

import allRunnersQuery from 'ee_else_ce/ci/runner/graphql/list/all_runners.query.graphql';
import allRunnersCountQuery from '~/ci/runner/graphql/list/all_runners_count.query.graphql';
import {
  runnersCountData,
  onlineContactTimeoutSecs,
  staleTimeoutSecs,
  mockRegistrationToken,
  newRunnerPath,
} from 'jest/ci/runner/mock_data';
import { allRunnersUpgradeStatusData } from '../mock_data';

const mockRunnersHandler = jest.fn();
const mockRunnersCountHandler = jest.fn();

Vue.use(VueApollo);

describe('AdminRunnersApp', () => {
  let wrapper;
  let cacheConfig;
  let localMutations;

  const findRunnerRows = () => wrapper.findComponent(RunnerList).findAll('tr');

  const createComponent = ({ props = {}, provide, ...options } = {}) => {
    ({ cacheConfig, localMutations } = createLocalState());

    const handlers = [
      [allRunnersQuery, mockRunnersHandler],
      [allRunnersCountQuery, mockRunnersCountHandler],
    ];

    wrapper = mountExtended(AdminRunnersApp, {
      apolloProvider: createMockApollo(handlers, {}, cacheConfig),
      propsData: {
        registrationToken: mockRegistrationToken,
        newRunnerPath,
        ...props,
      },
      provide: {
        localMutations,
        onlineContactTimeoutSecs,
        staleTimeoutSecs,
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
  });

  describe('upgrade icons', () => {
    beforeEach(async () => {
      await createComponent({
        provide: { glFeatures: { runnerUpgradeManagement: true } },
      });
    });

    it.each`
      version     | description                                | colorClass              | index
      ${'15.1.1'} | ${'displays no upgrade icon (up to date)'} | ${null}                 | ${1}
      ${'15.1.0'} | ${'displays upgrade recommended'}          | ${'gl-text-orange-500'} | ${2}
      ${'15.0.0'} | ${'displays upgrade available'}            | ${'gl-text-blue-500'}   | ${3}
    `('with $version $description', ({ version, index, colorClass }) => {
      const row = findRunnerRows().wrappers.map(extendedWrapper)[index];
      const upgradeIcon = row.findComponent(RunnerUpgradeStatusIcon);

      if (colorClass) {
        expect(upgradeIcon.classes()).toContain(colorClass);
      } else {
        expect(upgradeIcon.html()).toBe('');
      }

      expect(row.text()).toContain(version);
    });
  });
});
