import Vue, { nextTick } from 'vue';
import { GlTab, GlTable, GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { cloneDeep, merge } from 'lodash';
import allPipelinesWithPipelinesMock from 'test_fixtures/graphql/on_demand_scans/graphql/on_demand_scans.query.graphql.with_pipelines.json';
import allPipelinesWithoutPipelinesMock from 'test_fixtures/graphql/on_demand_scans/graphql/on_demand_scans.query.graphql.without_pipelines.json';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BaseTab from 'ee/on_demand_scans/components/tabs/base_tab.vue';
import Actions from 'ee/on_demand_scans/components/actions.vue';
import EmptyState from 'ee/on_demand_scans/components/empty_state.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import onDemandScansQuery from 'ee/on_demand_scans/graphql/on_demand_scans.query.graphql';
import { createRouter } from 'ee/on_demand_scans/router';
import waitForPromises from 'helpers/wait_for_promises';
import { scrollToElement } from '~/lib/utils/common_utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { BASE_TABS_TABLE_FIELDS, PIPELINES_POLL_INTERVAL } from 'ee/on_demand_scans/constants';
import * as sharedGraphQLUtils from '~/graphql_shared/utils';
import * as graphQlUtils from '~/pipelines/components/graph/utils';
import { PROJECT_ON_DEMAND_SCAN_COUNTS_ETAG_MOCK } from '../../mocks';

jest.mock('~/lib/utils/common_utils');

Vue.use(VueApollo);

const [firstPipeline] = allPipelinesWithPipelinesMock.data.project.pipelines.nodes;

describe('BaseTab', () => {
  let wrapper;
  let router;
  let requestHandler;

  // Props
  const projectPath = '/namespace/project';

  // Finders
  const findTitle = () => wrapper.findByTestId('tab-title');
  const findTable = () => wrapper.findComponent(GlTable);
  const findActions = () => wrapper.findComponent(Actions);
  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findPagination = () => wrapper.findByTestId('pagination');
  const findErrorAlert = () => wrapper.findComponent(GlAlert);
  const findFirstRow = () => wrapper.find('tbody > tr');
  const findCellAt = (index) => findFirstRow().findAll('td').at(index);

  // Helpers
  const createMockApolloProvider = () => {
    return createMockApollo([[onDemandScansQuery, requestHandler]]);
  };

  const navigateToPage = (direction, cursor = '') => {
    findPagination().vm.$emit(direction, cursor);
    return nextTick();
  };

  const setActiveState = (isActive) => {
    wrapper.setProps({ isActive });
    return nextTick();
  };

  const advanceToNextFetch = () => {
    jest.advanceTimersByTime(PIPELINES_POLL_INTERVAL);
  };

  const triggerActionError = async (errorMessage) => {
    findActions().vm.$emit('error', errorMessage);
    await nextTick();
  };

  const createComponentFactory = (mountFn = shallowMountExtended) => (
    options = {},
    canEditOnDemandScans = true,
  ) => {
    router = createRouter();
    wrapper = mountFn(
      BaseTab,
      merge(
        {
          apolloProvider: createMockApolloProvider(),
          router,
          propsData: {
            isActive: true,
            title: 'All',
            query: onDemandScansQuery,
            itemsCount: 0,
            fields: BASE_TABS_TABLE_FIELDS,
          },
          provide: {
            canEditOnDemandScans,
            projectPath,
            projectOnDemandScanCountsEtag: PROJECT_ON_DEMAND_SCAN_COUNTS_ETAG_MOCK,
          },
          stubs: {
            GlTab: stubComponent(GlTab, {
              template: `
            <div>
              <span data-testid="tab-title">
                <slot name="title" />
              </span>
              <slot />
            </div>
          `,
            }),
            GlTable: stubComponent(GlTable, {
              props: ['items', 'busy'],
            }),
          },
        },
        options,
      ),
    );
  };

  const createComponent = createComponentFactory();
  const createFullComponent = createComponentFactory(mountExtended);

  beforeEach(() => {
    requestHandler = jest.fn().mockResolvedValue(allPipelinesWithPipelinesMock);
  });

  describe('when the app loads', () => {
    it('formats the items count if it hit its max value', () => {
      const itemsCount = 10;
      createComponent({
        propsData: {
          itemsCount,
          maxItemsCount: itemsCount,
        },
      });

      expect(findTitle().text()).toMatchInterpolatedText(`All ${itemsCount}+`);
    });

    it('controls the pipelines query with a visibility check', () => {
      jest.spyOn(sharedGraphQLUtils, 'toggleQueryPollingByVisibility');
      createComponent();

      expect(sharedGraphQLUtils.toggleQueryPollingByVisibility).toHaveBeenCalledWith(
        wrapper.vm.$apollo.queries.pipelines,
        PIPELINES_POLL_INTERVAL,
      );
    });

    it('fetches the pipelines', () => {
      createComponent();

      expect(requestHandler).toHaveBeenCalledWith({
        after: null,
        before: null,
        first: 20,
        fullPath: projectPath,
        last: null,
      });
    });

    it('computes the ETag header', () => {
      jest.spyOn(graphQlUtils, 'getQueryHeaders');
      createComponent();

      expect(graphQlUtils.getQueryHeaders).toHaveBeenCalledWith(
        PROJECT_ON_DEMAND_SCAN_COUNTS_ETAG_MOCK,
      );
    });

    it('polls for pipelines as long as the tab is active', async () => {
      createComponent();

      expect(requestHandler).toHaveBeenCalledTimes(1);

      await waitForPromises();
      advanceToNextFetch();

      expect(requestHandler).toHaveBeenCalledTimes(2);

      await setActiveState(false);
      advanceToNextFetch();

      expect(requestHandler).toHaveBeenCalledTimes(2);

      await setActiveState(true);
      advanceToNextFetch();

      expect(requestHandler).toHaveBeenCalledTimes(3);
    });

    it('puts the table in the busy state until the request resolves', async () => {
      createComponent();

      expect(findTable().props('busy')).toBe(true);

      await waitForPromises();

      expect(findTable().props('busy')).toBe(false);
    });

    it('resets the route if no pipeline matches the cursor', async () => {
      setWindowLocation('#?after=nothingToSeeHere');
      requestHandler = jest.fn().mockResolvedValue(allPipelinesWithoutPipelinesMock);
      createComponent();

      expect(router.currentRoute.query.after).toBe('nothingToSeeHere');

      await waitForPromises();

      expect(router.currentRoute.query.after).toBeUndefined();
    });
  });

  describe('when there are pipelines', () => {
    beforeEach(async () => {
      createComponent({
        propsData: {
          itemsCount: 30,
        },
      });
      await waitForPromises();
    });

    it('renders the title with the item count', () => {
      expect(findTitle().text()).toMatchInterpolatedText('All 30');
    });

    it('passes the pipelines to GlTable', () => {
      const table = findTable();

      expect(table.exists()).toBe(true);
      expect(table.props('items')).toEqual(
        allPipelinesWithPipelinesMock.data.project.pipelines.nodes,
      );
    });

    it('when navigating to another page, scrolls back to the top', async () => {
      await navigateToPage('next');

      expect(scrollToElement).toHaveBeenCalledWith(wrapper.vm.$el);
    });

    it('when navigating to the next page, the route is updated and pipelines are fetched', async () => {
      expect(Object.keys(router.currentRoute.query)).not.toContain('after');
      expect(requestHandler).toHaveBeenCalledTimes(1);

      await navigateToPage('next');

      expect(Object.keys(router.currentRoute.query)).toContain('after');
      expect(requestHandler).toHaveBeenCalledTimes(2);
    });

    it('when navigating back to the previous page, the route is updated and pipelines are fetched', async () => {
      await navigateToPage('next');
      await waitForPromises();
      await navigateToPage('prev');

      expect(Object.keys(router.currentRoute.query)).not.toContain('after');
      expect(Object.keys(router.currentRoute.query)).toContain('before');
      expect(requestHandler).toHaveBeenCalledTimes(3);
    });

    it('when navigating to the next page, leaving the tab and coming back to it, the cursor is reset', async () => {
      const { endCursor } = allPipelinesWithPipelinesMock.data.project.pipelines.pageInfo;
      await navigateToPage('next', endCursor);

      expect(requestHandler).toHaveBeenNthCalledWith(
        2,
        expect.objectContaining({
          after: endCursor,
        }),
      );

      await setActiveState(false);
      await setActiveState(true);
      advanceToNextFetch();

      expect(requestHandler).toHaveBeenNthCalledWith(
        3,
        expect.objectContaining({
          after: null,
        }),
      );
    });
  });

  describe('rendered cells', () => {
    beforeEach(async () => {
      createFullComponent({
        propsData: {
          itemsCount: 30,
        },
        stubs: {
          GlTable: false,
        },
      });
      await waitForPromises();
    });

    it('renders the status badge', () => {
      const statusCell = findCellAt(0);

      expect(statusCell.text()).toBe(firstPipeline.detailedStatus.text);
    });

    it('renders the name with GlTruncate', () => {
      const nameCell = findCellAt(1);
      const truncateContainer = nameCell.find('[data-testid="truncate-end-container"]');

      expect(truncateContainer.exists()).toBe(true);
      expect(truncateContainer.text()).toBe(firstPipeline.dastProfile.name);
    });

    it('renders the scan type', () => {
      const scanTypeCell = findCellAt(2);

      expect(scanTypeCell.text()).toBe('DAST');
    });

    it('renders the target URL with GlTruncate', () => {
      const targetUrlCell = findCellAt(3);
      const truncateContainer = targetUrlCell.find('[data-testid="truncate-end-container"]');

      expect(truncateContainer.exists()).toBe(true);
      expect(truncateContainer.text()).toBe(firstPipeline.dastProfile.dastSiteProfile.targetUrl);
    });

    it('renders the start date as a timeElement', () => {
      const startDateCell = findCellAt(4);
      const timeElement = startDateCell.find('time');

      expect(timeElement.exists()).toBe(true);
      expect(timeElement.attributes('datetime')).toBe(firstPipeline.createdAt);
    });

    it('renders the pipeline ID', () => {
      const pipelineIdCell = findCellAt(5);

      expect(pipelineIdCell.text()).toBe(`#${getIdFromGraphQLId(firstPipeline.id)}`);
    });
  });

  it.each(['default', 'after-name', 'error'])('renders the %s slot', async (slot) => {
    createFullComponent({
      stubs: {
        GlTable: false,
      },
      scopedSlots: {
        [slot]: `<div data-testid="${slot}-slot-content" />`,
      },
    });
    await waitForPromises();

    expect(wrapper.findByTestId(`${slot}-slot-content`).exists()).toBe(true);
  });

  describe("when a scan's DAST profile got deleted", () => {
    beforeEach(() => {
      const allPipelinesWithPipelinesMockCopy = cloneDeep(allPipelinesWithPipelinesMock);
      const pipelineWithoutDastProfile = { ...firstPipeline, dastProfile: null };
      allPipelinesWithPipelinesMockCopy.data.project.pipelines.nodes[0] = pipelineWithoutDastProfile;

      requestHandler = jest.fn().mockResolvedValue(allPipelinesWithPipelinesMockCopy);
      createFullComponent({
        stubs: {
          GlTable: false,
        },
      });
      return waitForPromises();
    });

    it.each`
      cellName    | cellIndex
      ${'name'}   | ${1}
      ${'target'} | ${3}
    `('render empty $cellName cell', ({ cellIndex }) => {
      expect(findCellAt(cellIndex).text()).toBe('');
    });
  });

  describe('when there are no pipelines', () => {
    beforeEach(async () => {
      requestHandler = jest.fn().mockResolvedValue(allPipelinesWithoutPipelinesMock);
      createComponent();
      await waitForPromises();
    });

    it('renders an empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('when the request errors out', () => {
    let respondWithError;

    beforeEach(async () => {
      respondWithError = true;
      requestHandler = () => {
        const response = respondWithError
          ? Promise.reject()
          : Promise.resolve(allPipelinesWithPipelinesMock);
        respondWithError = false;
        return response;
      };
      createComponent();
      await waitForPromises();
    });

    it('shows an error alert', () => {
      expect(findErrorAlert().exists()).toBe(true);
    });

    it('removes the alert if the next request succeeds', async () => {
      expect(findErrorAlert().exists()).toBe(true);

      wrapper.vm.$apollo.queries.pipelines.refetch();
      await waitForPromises();

      expect(findErrorAlert().exists()).toBe(false);
    });
  });

  describe('actions', () => {
    const errorMessage = 'An error occurred.';

    beforeEach(() => {
      createFullComponent({
        stubs: {
          GlTable: false,
        },
      });
      return waitForPromises();
    });

    it('renders action cell', () => {
      expect(findActions().exists()).toBe(true);
    });

    it('shows action error message and scrolls back to the top on error', async () => {
      await triggerActionError(errorMessage);

      expect(wrapper.text()).toContain(errorMessage);
      expect(scrollToElement).toHaveBeenCalledWith(wrapper.vm.$el);
    });

    it('resets action error message on action', async () => {
      await triggerActionError(errorMessage);

      expect(wrapper.text()).toContain(errorMessage);

      findActions().vm.$emit('action');
      await waitForPromises();

      expect(wrapper.text()).not.toContain(errorMessage);
    });

    it('reset action error message when tab becomes active', async () => {
      await triggerActionError(errorMessage);

      expect(wrapper.text()).toContain(errorMessage);

      await setActiveState(false);
      await setActiveState(true);

      expect(wrapper.text()).not.toContain(errorMessage);
    });

    it('reset action error message on navigation', async () => {
      await triggerActionError(errorMessage);

      expect(wrapper.text()).toContain(errorMessage);

      await navigateToPage('next');

      expect(wrapper.text()).not.toContain(errorMessage);
    });
  });

  describe('user auditor role', () => {
    it.each`
      canEditOnDemandScans | expectedResult
      ${true}              | ${true}
      ${false}             | ${false}
    `(
      'should hide action buttons for auditor user',
      async ({ canEditOnDemandScans, expectedResult }) => {
        createFullComponent(
          {
            stubs: {
              GlTable: false,
            },
          },
          canEditOnDemandScans,
        );
        await waitForPromises();

        expect(findActions().exists()).toBe(expectedResult);
      },
    );
  });
});
