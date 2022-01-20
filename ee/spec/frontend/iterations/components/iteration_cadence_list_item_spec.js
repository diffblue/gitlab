import { GlDropdown, GlInfiniteScroll, GlModal, GlSkeletonLoader } from '@gitlab/ui';
import { createLocalVue, RouterLinkStub } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import IterationCadenceListItem from 'ee/iterations/components/iteration_cadence_list_item.vue';
import TimeboxStatusBadge from 'ee/iterations/components/timebox_status_badge.vue';
import { Namespace } from 'ee/iterations/constants';
import groupIterationsInCadenceQuery from 'ee/iterations/queries/group_iterations_in_cadence.query.graphql';
import projectIterationsInCadenceQuery from 'ee/iterations/queries/project_iterations_in_cadence.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended as mount } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

const { i18n } = IterationCadenceListItem;
const push = jest.fn();
const $router = {
  push,
};

const localVue = createLocalVue();

function createMockApolloProvider(requestHandlers) {
  localVue.use(VueApollo);

  return createMockApollo(requestHandlers);
}

describe('Iteration cadence list item', () => {
  let wrapper;
  let apolloProvider;

  const fullPath = 'gitlab-org';
  const iterations = [
    {
      dueDate: '2021-08-14',
      id: 'gid://gitlab/Iteration/41',
      scopedPath: '/groups/group1/-/iterations/41',
      startDate: '2021-08-13',
      state: 'upcoming',
      title: 'My title 44',
      webPath: '/groups/group1/-/iterations/41',
      __typename: 'Iteration',
    },
  ];

  const iterationPeriods = ['Aug 13, 2021 - Aug 14, 2021'];

  const cadence = {
    id: 'gid://gitlab/Iterations::Cadence/561',
    title: 'Weekly cadence',
    durationInWeeks: 3,
  };

  const startCursor = 'MQ';
  const endCursor = 'MjA';
  const querySuccessResponse = {
    data: {
      workspace: {
        id: '1',
        iterations: {
          nodes: iterations,
          pageInfo: {
            hasNextPage: true,
            hasPreviousPage: false,
            startCursor,
            endCursor,
          },
        },
      },
    },
  };

  const queryEmptyResponse = {
    data: {
      workspace: {
        id: '1',
        iterations: {
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
  function createComponent({
    props = {},
    canCreateIteration,
    canEditCadence,
    currentRoute,
    namespaceType = Namespace.Group,
    query = groupIterationsInCadenceQuery,
    resolverMock = jest.fn().mockResolvedValue(querySuccessResponse),
  } = {}) {
    apolloProvider = createMockApolloProvider([[query, resolverMock]]);

    wrapper = mount(IterationCadenceListItem, {
      localVue,
      apolloProvider,
      mocks: {
        $router: {
          ...$router,
          currentRoute,
        },
      },
      stubs: {
        RouterLink: RouterLinkStub,
      },
      provide: {
        fullPath,
        canCreateIteration,
        canEditCadence,
        namespaceType,
      },
      propsData: {
        title: cadence.title,
        cadenceId: cadence.id,
        iterationState: 'opened',
        ...props,
      },
    });

    return nextTick();
  }

  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findCreateIterationButton = () =>
    wrapper.findByRole('link', { text: i18n.createIteration });
  const expand = () => wrapper.findByRole('button', { text: cadence.title }).trigger('click');

  afterEach(() => {
    wrapper.destroy();
    apolloProvider = null;
  });

  it('does not query iterations when component mounted', async () => {
    const resolverMock = jest.fn();

    await createComponent({
      resolverMock,
    });

    expect(resolverMock).not.toHaveBeenCalled();
  });

  it.each(['opened', 'closed', 'all'])(
    'shows empty text when no results for list of %s iterations',
    async (iterationState) => {
      await createComponent({
        resolverMock: jest.fn().mockResolvedValue(queryEmptyResponse),
        props: {
          iterationState,
        },
      });

      expand();

      await waitForPromises();

      expect(findLoader().exists()).toBe(false);
      expect(wrapper.text()).toContain(i18n.noResults[iterationState]);
    },
  );

  it.each([
    ['hides', false],
    ['shows', true],
  ])('%s Create iteration button when canCreateIteration is %s', async (_, canCreateIteration) => {
    await createComponent({
      canCreateIteration,
      resolverMock: jest.fn().mockResolvedValue(queryEmptyResponse),
    });

    expand();

    await waitForPromises();

    expect(findCreateIterationButton().exists()).toBe(canCreateIteration);
  });

  it('shows iterations with dates after loading', async () => {
    await createComponent();

    expand();

    await waitForPromises();

    iterations.forEach(({ title }, i) => {
      expect(wrapper.text()).toContain(title);
      expect(wrapper.text()).toContain(iterationPeriods[i]);
    });
  });

  it('automatically expands for newly created cadence', async () => {
    await createComponent({
      currentRoute: { query: { createdCadenceId: getIdFromGraphQLId(cadence.id) } },
    });

    await waitForPromises();

    iterations.forEach(({ title }) => {
      expect(wrapper.text()).toContain(title);
    });
  });

  it('loads project iterations for Project namespaceType', async () => {
    await createComponent({
      namespaceType: Namespace.Project,
      query: projectIterationsInCadenceQuery,
    });

    expand();

    await waitForPromises();

    iterations.forEach(({ title }) => {
      expect(wrapper.text()).toContain(title);
    });
  });

  it('shows alert on query error', async () => {
    await createComponent({
      resolverMock: jest.fn().mockRejectedValue(queryEmptyResponse),
    });

    await expand();

    await waitForPromises();

    expect(findLoader().exists()).toBe(false);
    expect(wrapper.text()).toContain(i18n.error);
  });

  it('calls fetchMore after scrolling down', async () => {
    await createComponent();

    jest.spyOn(wrapper.vm.$apollo.queries.workspace, 'fetchMore').mockResolvedValue({});

    expand();

    await waitForPromises();

    wrapper.findComponent(GlInfiniteScroll).vm.$emit('bottomReached');

    expect(wrapper.vm.$apollo.queries.workspace.fetchMore).toHaveBeenCalledWith(
      expect.objectContaining({
        variables: expect.objectContaining({
          afterCursor: endCursor,
        }),
      }),
    );
  });

  describe('deleting cadence', () => {
    describe('canEditCadence = false', () => {
      beforeEach(async () => {
        await createComponent({
          canEditCadence: false,
        });
      });

      it('hides dropdown and delete button', () => {
        expect(wrapper.findComponent(GlDropdown).exists()).toBe(false);
      });
    });

    describe('canEditCadence = true', () => {
      beforeEach(async () => {
        createComponent({
          canEditCadence: true,
        });

        wrapper.vm.$refs.modal.show = jest.fn();
      });

      it('shows delete button', () => {
        expect(wrapper.findComponent(GlDropdown).exists()).toBe(true);
      });

      it('opens confirmation modal to delete cadence', () => {
        wrapper.findByTestId('delete-cadence').trigger('click');

        expect(wrapper.vm.$refs.modal.show).toHaveBeenCalled();
      });

      it('emits delete-cadence event with cadence ID', () => {
        wrapper.findComponent(GlModal).vm.$emit('ok');

        expect(wrapper.emitted('delete-cadence')).toEqual([[cadence.id]]);
      });
    });
  });

  it('hides dropdown when canEditCadence is false', async () => {
    await createComponent({ canEditCadence: false });

    expect(wrapper.findComponent(GlDropdown).exists()).toBe(false);
  });

  it('shows dropdown when canEditCadence is true', async () => {
    await createComponent({ canEditCadence: true });

    expect(wrapper.findComponent(GlDropdown).exists()).toBe(true);
  });

  it.each([
    ['hides', false],
    ['shows', true],
  ])('%s status badge when showStateBadge is %s', async (_, showStateBadge) => {
    await createComponent({ props: { showStateBadge } });

    expand();

    await waitForPromises();

    expect(wrapper.findComponent(TimeboxStatusBadge).exists()).toBe(showStateBadge);
  });
});
