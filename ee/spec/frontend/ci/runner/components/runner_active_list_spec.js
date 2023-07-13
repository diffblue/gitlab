import { GlLink, GlTable, GlSkeletonLoader } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import {
  extendedWrapper,
  shallowMountExtended,
  mountExtended,
} from 'helpers/vue_test_utils_helper';

import RunnerActiveList from 'ee/ci/runner/components/runner_active_list.vue';
import mostActiveRunnersQuery from 'ee/ci/runner/graphql/performance/most_active_runners.graphql';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import { captureException } from '~/ci/runner/sentry_utils';
import { JOBS_ROUTE_PATH } from '~/ci/runner/constants';

import { mostActiveRunnersData } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

const mostActiveRunners = mostActiveRunnersData.data.runners.nodes;
const [mockRunner, mockRunner2] = mostActiveRunners;

Vue.use(VueApollo);

describe('RunnerActiveList', () => {
  let wrapper;
  let mostActiveRunnersHandler;

  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaders = () => wrapper.findAll('thead th');
  const findRows = () => wrapper.findAll('tbody tr');
  const findCell = (row = 0, fieldKey) =>
    extendedWrapper(findRows().at(row).find(`[data-testid="td-${fieldKey}"]`));

  const createComponent = ({ mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerActiveList, {
      apolloProvider: createMockApollo([[mostActiveRunnersQuery, mostActiveRunnersHandler]]),
    });
  };

  beforeEach(() => {
    mostActiveRunnersHandler = jest.fn();
  });

  it('Requests most active runners', () => {
    createComponent();

    expect(mostActiveRunnersHandler).toHaveBeenCalledTimes(1);
  });

  describe('When loading data', () => {
    it('should show a loading skeleton', () => {
      createComponent({ mountFn: mountExtended });

      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });
  });

  describe('When there are active runners', () => {
    beforeEach(async () => {
      mostActiveRunnersHandler.mockResolvedValue(mostActiveRunnersData);

      createComponent({ mountFn: mountExtended });
      await waitForPromises();
    });

    it('shows table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('shows headers', () => {
      const headers = findHeaders().wrappers.map((w) => w.text());
      expect(headers).toEqual(['', s__('Runners|Runner'), s__('Runners|Running Jobs')]);
    });

    it('shows runners', () => {
      expect(findRows()).toHaveLength(mostActiveRunners.length);

      // Row 1
      const runner = `#${getIdFromGraphQLId(mockRunner.id)} (${mockRunner.shortSha}) - ${
        mockRunner.description
      }`;
      expect(findCell(0, 'index').text()).toBe('1');
      expect(findCell(0, 'runner').text()).toBe(runner);
      expect(findCell(0, 'runningJobCount').text()).toBe('2');

      // Row 2
      const runner2 = `#${getIdFromGraphQLId(mockRunner2.id)} (${mockRunner2.shortSha}) - ${
        mockRunner2.description
      }`;
      expect(findCell(1, 'index').text()).toBe('2');
      expect(findCell(1, 'runner').text()).toBe(runner2);
      expect(findCell(1, 'runningJobCount').text()).toBe('1');
    });

    it('shows jobs link', async () => {
      createComponent({ mountFn: mountExtended });
      await waitForPromises();

      const url = findCell(0, 'runningJobCount').findComponent(GlLink).attributes('href');
      expect(url).toBe(`${mockRunner.adminUrl}#${JOBS_ROUTE_PATH}`);
    });
  });

  describe('When there are no runners', () => {
    beforeEach(async () => {
      mostActiveRunnersHandler.mockResolvedValueOnce({
        data: {
          runners: {
            nodes: [],
          },
        },
      });

      createComponent({ mountFn: mountExtended });
      await waitForPromises();
    });

    it('should render no runners', () => {
      expect(findTable().exists()).toBe(false);

      expect(wrapper.text()).toContain('no runners');
    });
  });

  describe('When an error occurs', () => {
    beforeEach(async () => {
      mostActiveRunnersHandler.mockRejectedValue(new Error('Error!'));

      createComponent();
      await waitForPromises();
    });

    it('shows an error', () => {
      expect(createAlert).toHaveBeenCalled();
    });

    it('reports an error', () => {
      expect(captureException).toHaveBeenCalledWith({
        component: 'RunnerActiveList',
        error: expect.any(Error),
      });
    });
  });
});
