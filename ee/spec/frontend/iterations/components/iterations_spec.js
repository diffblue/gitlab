import { GlAlert, GlEmptyState, GlLoadingIcon, GlPagination, GlTab, GlTabs } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Iterations from 'ee/iterations/components/iterations.vue';
import IterationsList from 'ee/iterations/components/iterations_list.vue';
import { Namespace } from 'ee/iterations/constants';
import query from 'ee/iterations/queries/iterations.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockGroupIterations, mockGroupIterationsEmpty } from '../mock_data';

describe('Iterations', () => {
  let wrapper;
  let mockApollo;
  const defaultProps = {
    fullPath: 'gitlab-org',
  };

  const mountComponent = ({
    props = defaultProps,
    queryResponse = mockGroupIterations,
    queryHandler = jest.fn().mockResolvedValue(queryResponse),
  } = {}) => {
    Vue.use(VueApollo);

    mockApollo = createMockApollo([[query, queryHandler]]);

    wrapper = shallowMount(Iterations, {
      apolloProvider: mockApollo,
      propsData: props,
      stubs: {
        GlLoadingIcon,
        GlTab,
        GlTabs,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('hides list while loading', () => {
    mountComponent();

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    expect(wrapper.findComponent(IterationsList).exists()).toBe(false);
  });

  it('shows iterations list after loading', async () => {
    mountComponent({
      props: { ...defaultProps, newIterationPath: 'iterations' },
    });

    await waitForPromises();

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
    expect(wrapper.findComponent(IterationsList).exists()).toBe(true);
  });

  it('sets computed state from tabIndex', () => {
    mountComponent();

    expect(wrapper.vm.state).toEqual('opened');

    wrapper.vm.tabIndex = 1;

    expect(wrapper.vm.state).toEqual('closed');

    wrapper.vm.tabIndex = 2;

    expect(wrapper.vm.state).toEqual('all');
  });

  describe('when loading is false and iterations are empty', () => {
    beforeEach(async () => {
      mountComponent({
        props: {
          ...defaultProps,
          newIterationPath: 'iterations',
        },
        queryResponse: mockGroupIterationsEmpty,
      });

      await waitForPromises();
    });

    it('renders GlEmptyState with the correct props', () => {
      expect(wrapper.findComponent(GlEmptyState).props()).toEqual(
        expect.objectContaining({ primaryButtonLink: 'iterations' }),
      );
    });
  });

  describe('pagination', () => {
    const findPagination = () => wrapper.findComponent(GlPagination);
    const setPage = async (page) => {
      findPagination().vm.$emit('input', page);
      await nextTick();
    };

    beforeEach(async () => {
      mountComponent({
        queryResponse: mockGroupIterations,
      });

      await waitForPromises();
    });

    it('passes prev, next, and current page props', () => {
      expect(findPagination().exists()).toBe(true);
      expect(findPagination().props()).toEqual(
        expect.objectContaining({
          value: wrapper.vm.pagination.currentPage,
          prevPage: wrapper.vm.prevPage,
          nextPage: wrapper.vm.nextPage,
        }),
      );
    });

    it('updates query variables when going to previous page', async () => {
      await setPage(1);

      expect(wrapper.vm.queryVariables).toEqual({
        beforeCursor: 'first-item',
        isGroup: true,
        lastPageSize: 20,
        fullPath: defaultProps.fullPath,
        state: 'opened',
      });
    });

    it('updates query variables when going to next page', async () => {
      await setPage(2);

      expect(wrapper.vm.queryVariables).toEqual({
        afterCursor: 'last-item',
        firstPageSize: 20,
        fullPath: defaultProps.fullPath,
        isGroup: true,
        state: 'opened',
      });
    });

    it('resets pagination when changing tabs', async () => {
      await setPage(2);

      expect(wrapper.vm.pagination).toEqual({
        currentPage: 2,
        afterCursor: 'last-item',
      });

      wrapper.findComponent(GlTabs).vm.$emit('activate-tab', 2);

      await nextTick();

      expect(wrapper.vm.pagination).toEqual({
        currentPage: 1,
      });
    });
  });

  describe('iterations query variables', () => {
    const expected = {
      afterCursor: undefined,
      firstPageSize: 20,
      fullPath: defaultProps.fullPath,
      state: 'opened',
    };

    describe('when group', () => {
      it('has expected query variable values', () => {
        mountComponent({
          props: {
            ...defaultProps,
            namespaceType: Namespace.Group,
          },
        });

        expect(wrapper.vm.queryVariables).toEqual({
          ...expected,
          isGroup: true,
        });
      });
    });

    describe('when project', () => {
      it('has expected query variable values', () => {
        mountComponent({
          props: {
            ...defaultProps,
            namespaceType: Namespace.Project,
          },
        });

        expect(wrapper.vm.queryVariables).toEqual({
          ...expected,
          isGroup: false,
        });
      });
    });
  });

  describe('error', () => {
    beforeEach(async () => {
      mountComponent({
        queryHandler: jest.fn().mockRejectedValue({
          data: {
            group: {
              errors: ['oh no'],
            },
          },
        }),
      });

      await waitForPromises();
    });

    it('tab shows error in alert', () => {
      expect(wrapper.findComponent(GlAlert).text()).toContain('Error loading iterations');
    });
  });
});
