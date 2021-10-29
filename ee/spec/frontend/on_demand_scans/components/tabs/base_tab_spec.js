import { GlTab, GlTable } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import allPipelinesWithPipelinesMock from 'test_fixtures/graphql/on_demand_scans/graphql/on_demand_scans.query.graphql.with_pipelines.json';
import allPipelinesWithoutPipelinesMock from 'test_fixtures/graphql/on_demand_scans/graphql/on_demand_scans.query.graphql.without_pipelines.json';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BaseTab from 'ee/on_demand_scans/components/tabs/base_tab.vue';
import EmptyState from 'ee/on_demand_scans/components/empty_state.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import onDemandScansQuery from 'ee/on_demand_scans/graphql/on_demand_scans.query.graphql';
import { createRouter } from 'ee/on_demand_scans/router';
import waitForPromises from 'helpers/wait_for_promises';
import { scrollToElement } from '~/lib/utils/common_utils';
import setWindowLocation from 'helpers/set_window_location_helper';

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

  // Helpers
  const createMockApolloProvider = () => {
    return createMockApollo([[onDemandScansQuery, requestHandler]]);
  };

  const createComponent = (propsData) => {
    router = createRouter();
    wrapper = shallowMountExtended(BaseTab, {
      localVue,
      apolloProvider: createMockApolloProvider(),
      router,
      propsData: {
        title: 'All',
        query: onDemandScansQuery,
        itemsCount: 0,
        fields: [{ name: 'ID', key: 'id' }],
        ...propsData,
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
          props: ['items'],
        }),
      },
    });
  };

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
        itemsCount: 30,
      });
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

    it('when navigating to another page, scrolls back to the top', () => {
      findPagination().vm.$emit('next');

      expect(scrollToElement).toHaveBeenCalledWith(wrapper.vm.$el);
    });

    it('when navigating to the next page, the route is updated and pipelines are fetched', async () => {
      expect(Object.keys(router.currentRoute.query)).not.toContain('after');
      expect(requestHandler).toHaveBeenCalledTimes(1);

      findPagination().vm.$emit('next');
      await wrapper.vm.$nextTick();

      expect(Object.keys(router.currentRoute.query)).toContain('after');
      expect(requestHandler).toHaveBeenCalledTimes(2);
    });

    it('when navigating back to the previous page, the route is updated and pipelines are fetched', async () => {
      findPagination().vm.$emit('next');
      await wrapper.vm.$nextTick();
      findPagination().vm.$emit('prev');
      await wrapper.vm.$nextTick();

      expect(Object.keys(router.currentRoute.query)).not.toContain('after');
      expect(Object.keys(router.currentRoute.query)).toContain('before');
      expect(requestHandler).toHaveBeenCalledTimes(3);
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
});
