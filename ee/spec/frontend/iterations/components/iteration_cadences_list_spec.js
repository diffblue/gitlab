import { GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import IterationCadenceListItem from 'ee/iterations/components/iteration_cadence_list_item.vue';
import IterationCadencesList from 'ee/iterations/components/iteration_cadences_list.vue';
import destroyIterationCadence from 'ee/iterations/queries/destroy_cadence.mutation.graphql';
import cadencesListQuery from 'ee/iterations/queries/group_iteration_cadences_list.query.graphql';
import projectCadencesListQuery from 'ee/iterations/queries/project_iteration_cadences_list.query.graphql';
import createRouter from 'ee/iterations/router';
import createMockApollo from 'helpers/mock_apollo_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { mountExtended as mount } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';

const baseUrl = '/cadences/';
const router = createRouter(baseUrl);

function createMockApolloProvider(requestHandlers) {
  Vue.use(VueApollo);

  return createMockApollo(requestHandlers);
}

describe('Iteration cadences list', () => {
  let wrapper;
  let apolloProvider;

  const cadencesListPath = TEST_HOST;
  const fullPath = 'gitlab-org';
  const cadences = [
    {
      id: 'gid://gitlab/Iterations::Cadence/561',
      title: 'A eligendi molestias temporibus maiores architecto ut facilis autem.',
      durationInWeeks: 3,
      automatic: true,
    },
    {
      id: 'gid://gitlab/Iterations::Cadence/392',
      title: 'A quam repellat omnis eum veritatis voluptas voluptatem consequuntur est.',
      durationInWeeks: 4,
      automatic: true,
    },
    {
      id: 'gid://gitlab/Iterations::Cadence/152',
      title: 'A repudiandae ut eligendi quae et ducimus porro nam sint perferendis.',
      durationInWeeks: 1,
      automatic: true,
    },
  ];

  const startCursor = 'MQ';
  const endCursor = 'MjA';
  const querySuccessResponse = (nodes = cadences) => {
    return {
      data: {
        workspace: {
          id: 'id',
          iterationCadences: {
            nodes,
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor,
              endCursor,
            },
          },
        },
      },
    };
  };

  const queryEmptyResponse = {
    data: {
      workspace: {
        id: '234',
        iterationCadences: {
          nodes: [],
          pageInfo: {
            hasNextPage: false,
            hasPreviousPage: false,
            startCursor: null,
            endCursor: null,
          },
        },
      },
    },
  };

  const queryErrorResponse = {
    message: 'Network error',
  };

  function createComponent({
    canCreateCadence,
    canEditCadence,
    namespaceType = WORKSPACE_GROUP,
    query = cadencesListQuery,
    resolverMock = jest.fn().mockResolvedValue(querySuccessResponse()),
    destroyMutationMock = jest
      .fn()
      .mockResolvedValue({ data: { iterationCadenceDestroy: { errors: [] } } }),
  } = {}) {
    apolloProvider = createMockApolloProvider([
      [query, resolverMock],
      [destroyIterationCadence, destroyMutationMock],
    ]);

    wrapper = mount(IterationCadencesList, {
      apolloProvider,
      router,
      provide: {
        fullPath,
        namespaceType,
        cadencesListPath,
        canCreateCadence,
        canCreateIteration: false,
        canEditCadence,
      },
    });

    return nextTick();
  }

  const createCadenceButton = () =>
    wrapper.findByRole('link', { name: 'New iteration cadence', href: cadencesListPath });
  const findNextPageButton = () => wrapper.findByRole('button', { name: 'Next' });
  const findPrevPageButton = () => wrapper.findByRole('button', { name: 'Prev' });
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  afterEach(() => {
    apolloProvider = null;
  });

  describe('Create cadence button', () => {
    it('is shown when canCreateCadence is true', async () => {
      await createComponent({ canCreateCadence: true });

      expect(createCadenceButton().exists()).toBe(true);
    });

    it('is hidden when canCreateCadence is false', async () => {
      await createComponent({
        canCreateCadence: false,
      });

      expect(createCadenceButton().exists()).toBe(false);
    });
  });

  describe('cadences list', () => {
    it('shows loading state on mount', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('shows empty text when no results', async () => {
      await createComponent({
        resolverMock: jest.fn().mockResolvedValue(queryEmptyResponse),
      });

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findPagination().exists()).toBe(false);
      expect(wrapper.text()).toContain('No iteration cadences to show');
    });

    it('shows cadences after loading', async () => {
      await createComponent();

      await waitForPromises();

      cadences.forEach(({ title }) => {
        expect(wrapper.text()).toContain(title);
      });
    });

    it('loads project iterations for Project namespaceType', async () => {
      await createComponent({
        namespaceType: WORKSPACE_PROJECT,
        query: projectCadencesListQuery,
      });

      await waitForPromises();

      cadences.forEach(({ title }) => {
        expect(wrapper.text()).toContain(title);
      });
    });

    it('shows alert on query error', async () => {
      await createComponent({
        resolverMock: jest.fn().mockRejectedValue(queryErrorResponse),
      });

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(wrapper.text()).toContain('Network error');
    });

    describe('pagination', () => {
      let resolverMock;

      beforeEach(async () => {
        resolverMock = jest.fn().mockResolvedValue(querySuccessResponse());
        await createComponent({ resolverMock });
        await waitForPromises();

        resolverMock.mockReset();
      });

      it('correctly disables pagination buttons', () => {
        expect(findNextPageButton().element).not.toBeDisabled();
        expect(findPrevPageButton().element).toBeDisabled();
      });

      it('updates query when next page clicked', async () => {
        findPagination().vm.$emit('next');

        await nextTick();

        expect(resolverMock).toHaveBeenCalledWith(
          expect.objectContaining({
            beforeCursor: '',
            afterCursor: endCursor,
          }),
        );
      });

      it('updates query when previous page clicked', async () => {
        findPagination().vm.$emit('prev');

        await nextTick();

        expect(resolverMock).toHaveBeenCalledWith(
          expect.objectContaining({
            beforeCursor: startCursor,
            afterCursor: '',
          }),
        );
      });
    });

    describe('deleting cadence', () => {
      it('removes item from list', async () => {
        await createComponent({
          canEditCadence: true,
        });

        await waitForPromises();

        // 3 cadences * 3 tabs, so 9 in total
        expect(wrapper.findAllComponents(IterationCadenceListItem).length).toBe(9);
        expect(wrapper.text()).toContain(cadences[0].title);

        wrapper.findComponent(IterationCadenceListItem).vm.$emit('delete-cadence', cadences[0].id);

        await waitForPromises();

        expect(wrapper.findAllComponents(IterationCadenceListItem).length).toBe(6);
        expect(wrapper.text()).not.toContain(cadences[0].title);
      });
    });
  });
});
