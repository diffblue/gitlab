import { GlDropdown, GlInfiniteScroll, GlModal, GlSkeletonLoader } from '@gitlab/ui';
import { RouterLinkStub } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';
import IterationCadenceListItem from 'ee/iterations/components/iteration_cadence_list_item.vue';
import TimeboxStatusBadge from 'ee/iterations/components/timebox_status_badge.vue';
import { CADENCE_AND_DUE_DATE_DESC } from 'ee/iterations/constants';
import { getIterationPeriod } from 'ee/iterations/utils';
import groupIterationsInCadenceQuery from 'ee/iterations/queries/group_iterations_in_cadence.query.graphql';
import projectIterationsInCadenceQuery from 'ee/iterations/queries/project_iterations_in_cadence.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended as mount } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { automaticIterationCadence } from '../mock_data';

const { i18n } = IterationCadenceListItem;
const push = jest.fn();
const $router = {
  push,
};

function createMockApolloProvider(requestHandlers) {
  Vue.use(VueApollo);

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
    {
      id: 'gid://gitlab/Iteration/42',
      scopedPath: '/groups/group1/-/iterations/42',
      startDate: '2021-08-15',
      dueDate: '2021-08-20',
      state: 'upcoming',
      title: null,
      webPath: '/groups/group1/-/iterations/42',
      __typename: 'Iteration',
    },
  ];

  const startCursor = 'MQ';
  const endCursor = 'MjA';
  const querySuccessResponse = {
    data: {
      workspace: {
        id: '1',
        iterations: {
          nodes: iterations,
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
    cadence = automaticIterationCadence,
    namespaceType = WORKSPACE_GROUP,
    query = groupIterationsInCadenceQuery,
    resolverMock = jest.fn().mockResolvedValue(querySuccessResponse),
  } = {}) {
    apolloProvider = createMockApolloProvider([[query, resolverMock]]);

    wrapper = mount(IterationCadenceListItem, {
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
        automatic: true,
        iterationState: 'opened',
        ...props,
      },
    });

    return nextTick();
  }

  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAddIterationButton = () => wrapper.findByRole('menuitem', { name: i18n.addIteration });
  const findIterationItemText = (i) => wrapper.findAllByTestId('iteration-item').at(i).text();
  const findDurationBadge = () => wrapper.find('[data-testid="duration-badge"]');
  const expand = (cadence = automaticIterationCadence) =>
    wrapper.findByRole('button', { text: cadence.title }).trigger('click');

  afterEach(() => {
    apolloProvider = null;
  });

  it('does not query iterations when component mounted', async () => {
    const resolverMock = jest.fn();

    await createComponent({
      resolverMock,
    });

    expect(resolverMock).not.toHaveBeenCalled();
  });

  it.each([
    {
      namespaceType: WORKSPACE_GROUP,
      query: groupIterationsInCadenceQuery,
    },
    {
      namespaceType: WORKSPACE_PROJECT,
      query: projectIterationsInCadenceQuery,
    },
  ])('uses DESC sort order for closed iterations', async (params) => {
    const iterationsQueryHandler = jest.fn().mockResolvedValue(queryEmptyResponse);

    await createComponent({
      resolverMock: iterationsQueryHandler,
      props: {
        iterationState: 'closed',
      },
      query: params.query,
      namespaceType: params.namespaceType,
    });

    expand();

    await waitForPromises();

    expect(iterationsQueryHandler).toHaveBeenCalledWith(
      expect.objectContaining({ sort: CADENCE_AND_DUE_DATE_DESC }),
    );
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

  it('hides Add iteration button for automatic cadence', async () => {
    await createComponent({
      canCreateIteration: true,
      canEditCadence: true,
    });

    expand();

    await waitForPromises();

    expect(findAddIterationButton().exists()).toBe(false);
  });

  it.each([
    ['hides', false],
    ['shows', true],
  ])(
    '%s Add iteration button when canCreateIteration is %s for manual cadence',
    async (_, canCreateIteration) => {
      await createComponent({
        props: {
          automatic: false,
        },
        canCreateIteration,
        canEditCadence: true,
        resolverMock: jest.fn().mockResolvedValue(queryEmptyResponse),
      });

      expand();

      await waitForPromises();

      expect(findAddIterationButton().exists()).toBe(canCreateIteration);
    },
  );

  describe('duration badge', () => {
    it('does not show duration badge for manual cadence', async () => {
      await createComponent({
        props: {
          automatic: false,
          durationInWeeks: 2,
        },
      });

      expect(findDurationBadge().exists()).toBe(false);
    });

    it('shows duration badge for automatic cadence', async () => {
      await createComponent({
        props: {
          automatic: true,
          durationInWeeks: 2,
        },
      });

      expect(findDurationBadge().exists()).toBe(true);
    });
  });

  const expectIterationItemToHavePeriod = () => {
    iterations.forEach(({ startDate, dueDate }, i) => {
      const containedText = findIterationItemText(i);

      expect(containedText).toContain(getIterationPeriod({ startDate, dueDate }));
    });
  };

  it('shows iteration dates after loading', async () => {
    await createComponent();

    expand();

    await waitForPromises();

    expectIterationItemToHavePeriod();
  });

  it('automatically expands for newly created cadence', async () => {
    await createComponent({
      currentRoute: {
        query: { createdCadenceId: getIdFromGraphQLId(automaticIterationCadence.id) },
      },
    });

    await waitForPromises();

    expectIterationItemToHavePeriod();
  });

  it('loads project iterations for Project namespaceType', async () => {
    await createComponent({
      namespaceType: WORKSPACE_PROJECT,
      query: projectIterationsInCadenceQuery,
    });

    expand();

    await waitForPromises();

    expectIterationItemToHavePeriod();
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
      beforeEach(() => {
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

        expect(wrapper.emitted('delete-cadence')).toEqual([[automaticIterationCadence.id]]);
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
