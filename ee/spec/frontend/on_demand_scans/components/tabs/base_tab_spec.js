import { GlTab, GlTable, GlAlert } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { merge } from 'lodash';
import allPipelinesWithPipelinesMock from 'test_fixtures/graphql/on_demand_scans/graphql/on_demand_scans.query.graphql.with_pipelines.json';
import allPipelinesWithoutPipelinesMock from 'test_fixtures/graphql/on_demand_scans/graphql/on_demand_scans.query.graphql.without_pipelines.json';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BaseTab from 'ee/on_demand_scans/components/tabs/base_tab.vue';
import EmptyState from 'ee/on_demand_scans/components/empty_state.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import onDemandScansQuery from 'ee/on_demand_scans/graphql/on_demand_scans.query.graphql';
import { createRouter } from 'ee/on_demand_scans/router';
import waitForPromises from 'helpers/wait_for_promises';
import { scrollToElement } from '~/lib/utils/common_utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

jest.mock('~/lib/utils/common_utils');

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('BaseTab', () => {
  let wrapper;
  let router;
  let requestHandler;

  // Props
  const projectPath = '/namespace/project';

  // Finders
  const findTitle = () => wrapper.findByTestId('tab-title');
  const findTable = () => wrapper.findComponent(GlTable);
  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findPagination = () => wrapper.findByTestId('pagination');
  const findErrorAlert = () => wrapper.findComponent(GlAlert);

  // Helpers
  const createMockApolloProvider = () => {
    return createMockApollo([[onDemandScansQuery, requestHandler]]);
  };

  const navigateToPage = (direction) => {
    findPagination().vm.$emit(direction);
    return wrapper.vm.$nextTick();
  };

  const createComponentFactory = (mountFn = shallowMountExtended) => (options = {}) => {
    router = createRouter();
    wrapper = mountFn(
      BaseTab,
      merge(
        {
          localVue,
          apolloProvider: createMockApolloProvider(),
          router,
          propsData: {
            title: 'All',
            query: onDemandScansQuery,
            itemsCount: 0,
            fields: [
              {
                label: 'Status',
                key: 'detailedStatus',
              },
              {
                label: 'Name',
                key: 'dastProfile.name',
              },
              {
                label: 'OnDemandScans|Scan type',
                key: 'scanType',
              },
              {
                label: 'OnDemandScans|Target',
                key: 'dastProfile.dastSiteProfile.targetUrl',
              },
              {
                label: 'Start date',
                key: 'createdAt',
              },
              {
                label: 'Pipeline',
                key: 'id',
              },
            ],
          },
          provide: {
            projectPath,
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

  afterEach(() => {
    wrapper.destroy();
    router = null;
    requestHandler = null;
  });

  describe('when the app loads', () => {
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
    beforeEach(() => {
      createComponent({
        propsData: {
          itemsCount: 30,
        },
      });
    });

    it('renders the title with the item count', async () => {
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
  });

  describe('rendered cells', () => {
    const [firstPipeline] = allPipelinesWithPipelinesMock.data.project.pipelines.nodes;

    const findFirstRow = () => wrapper.find('tbody > tr');
    const findCellAt = (index) => findFirstRow().findAll('td').at(index);

    beforeEach(() => {
      createFullComponent({
        propsData: {
          itemsCount: 30,
        },
        stubs: {
          GlTable: false,
        },
      });
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

  describe('when there are no pipelines', () => {
    beforeEach(() => {
      requestHandler = jest.fn().mockResolvedValue(allPipelinesWithoutPipelinesMock);
      createComponent();
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
});
