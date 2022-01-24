import { GlDropdown, GlEmptyState, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import IterationReport from 'ee/iterations/components/iteration_report.vue';
import IterationReportTabs from 'ee/iterations/components/iteration_report_tabs.vue';
import TimeboxStatusBadge from 'ee/iterations/components/timebox_status_badge.vue';
import { Namespace } from 'ee/iterations/constants';
import deleteIteration from 'ee/iterations/queries/destroy_iteration.mutation.graphql';
import query from 'ee/iterations/queries/iteration.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { mockIterationNode, mockGroupIterations, mockProjectIterations } from '../mock_data';

const $router = {
  push: jest.fn(),
  currentRoute: {
    params: {
      iterationId: String(getIdFromGraphQLId(mockIterationNode.id)),
    },
  },
};
const $toast = {
  show: jest.fn(),
};

describe('Iterations report', () => {
  let wrapper;
  let mockApollo;

  const defaultProps = {
    fullPath: 'gitlab-org',
    namespaceType: Namespace.Group,
  };
  const labelsFetchPath = '/labels.json';

  const findTopbar = () => wrapper.findComponent({ ref: 'topbar' });
  const findTitle = () => wrapper.findComponent({ ref: 'title' });
  const findDescription = () => wrapper.findComponent({ ref: 'description' });
  const findActionsDropdown = () => wrapper.find('[data-testid="actions-dropdown"]');

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const mountComponent = ({
    props = defaultProps,
    mockQueryResponse = mockGroupIterations,
    iterationQueryHandler = jest.fn().mockResolvedValue(mockQueryResponse),
    deleteMutationResponse = { data: { iterationDelete: { errors: [] } } },
    deleteMutationMock = jest.fn().mockResolvedValue(deleteMutationResponse),
  } = {}) => {
    Vue.use(VueApollo);
    mockApollo = createMockApollo([
      [query, iterationQueryHandler],
      [deleteIteration, deleteMutationMock],
    ]);

    wrapper = shallowMount(IterationReport, {
      apolloProvider: mockApollo,
      propsData: props,
      provide: {
        fullPath: props.fullPath,
        groupPath: props.fullPath,
        cadencesListPath: '/groups/some-group/-/cadences',
        canCreateCadence: true,
        canEditCadence: true,
        namespaceType: props.namespaceType,
        canEditIteration: props.canEditIteration,
        hasScopedLabelsFeature: true,
        labelsFetchPath,
        previewMarkdownPath: '/markdown',
        noIssuesSvgPath: '/some.svg',
      },
      mocks: {
        $router,
        $toast,
      },
      stubs: {
        GlLoadingIcon,
        GlTab,
        GlTabs,
      },
    });
  };

  describe('with mock apollo', () => {
    describe.each([
      [
        'group',
        {
          fullPath: 'group-name',
          iterationId: String(getIdFromGraphQLId(mockIterationNode.id)),
          namespaceType: Namespace.Group,
        },
        mockGroupIterations,
        {
          fullPath: 'group-name',
          id: mockIterationNode.id,
          isGroup: true,
        },
      ],
      [
        'project',
        {
          fullPath: 'group-name/project-name',
          iterationId: String(getIdFromGraphQLId(mockIterationNode.id)),
          namespaceType: Namespace.Project,
        },
        mockProjectIterations,
        {
          fullPath: 'group-name/project-name',
          id: mockIterationNode.id,
          isGroup: false,
        },
      ],
    ])('when viewing an iteration in a %s', (_, props, mockIteration, expectedParams) => {
      it('calls a query with correct parameters', () => {
        const iterationQueryHandler = jest.fn().mockResolvedValue(mockIteration);
        mountComponent({
          props,
          iterationQueryHandler,
        });

        expect(iterationQueryHandler).toHaveBeenNthCalledWith(1, expectedParams);
      });

      it('renders an iteration title', async () => {
        mountComponent({
          props,
          iterationQueryHandler: jest.fn().mockResolvedValue(mockIteration),
        });

        await waitForPromises();

        expect(findTitle().text()).toContain(mockIterationNode.title);
      });
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('delete iteration', () => {
    it('deletes iteration', async () => {
      mountComponent();

      wrapper.vm.deleteIteration();

      await waitForPromises();

      expect($router.push).toHaveBeenCalledWith('/');
      expect($toast.show).toHaveBeenCalledWith('The iteration has been deleted.');
    });

    it('shows error when delete fails', async () => {
      mountComponent({
        deleteMutationResponse: {
          data: {
            iterationDelete: {
              errors: [
                "upcoming/current iterations can't be deleted unless they are the last one in the cadence",
              ],
              __typename: 'IterationDeletePayload',
            },
          },
        },
      });

      wrapper.vm.deleteIteration();

      await waitForPromises();

      expect($router.push).not.toHaveBeenCalled();
    });

    it('shows error when delete rejects', async () => {
      mountComponent({
        deleteMutationMock: jest.fn().mockRejectedValue({
          data: {
            iterationDelete: {
              errors: [
                "upcoming/current iterations can't be deleted unless they are the last one in the cadence",
              ],
              __typename: 'IterationDeletePayload',
            },
          },
        }),
      });

      wrapper.vm.deleteIteration();

      await waitForPromises();

      expect($router.push).not.toHaveBeenCalled();
    });
  });

  describe('empty state', () => {
    it('shows empty state if no item loaded', async () => {
      mountComponent({
        iterationQueryHandler: jest.fn().mockResolvedValue({
          data: {
            group: {
              id: 'gid://gitlab/Group/1',
              iterations: {
                nodes: [],
              },
            },
          },
        }),
      });

      await waitForPromises();

      expect(findEmptyState().props('title')).toBe('Could not find iteration');
      expect(findTitle().exists()).toBe(false);
      expect(findDescription().exists()).toBe(false);
      expect(findActionsDropdown().exists()).toBe(false);
    });
  });

  describe('item loaded', () => {
    describe('user without edit permission', () => {
      beforeEach(async () => {
        mountComponent({
          iterationQueryHandler: jest.fn().mockResolvedValue(mockGroupIterations),
        });

        await waitForPromises();
      });

      it('shows status and date in header', () => {
        const startDate = IterationReport.methods.formatDate(mockIterationNode.startDate);
        const dueDate = IterationReport.methods.formatDate(mockIterationNode.startDate);
        expect(wrapper.findComponent(TimeboxStatusBadge).props('state')).toContain(
          mockIterationNode.state,
        );
        expect(findTopbar().text()).toContain(startDate);
        expect(findTopbar().text()).toContain(dueDate);
      });

      it('hides empty region and loading spinner', () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(false);
      });

      it('shows title', () => {
        expect(findTitle().text()).toContain(mockIterationNode.title);
      });

      it('shows description', () => {
        expect(findDescription().text()).toContain(mockIterationNode.description);
      });

      it('hides actions dropdown', () => {
        expect(findActionsDropdown().exists()).toBe(false);
      });

      it('shows IterationReportTabs component', () => {
        const iterationReportTabs = wrapper.findComponent(IterationReportTabs);

        expect(iterationReportTabs.props()).toMatchObject({
          fullPath: defaultProps.fullPath,
          iterationId: mockIterationNode.id,
          labelsFetchPath,
          namespaceType: Namespace.Group,
        });
      });
    });

    describe('actions dropdown to edit iteration', () => {
      describe.each`
        description                    | canEditIteration | namespaceType        | canEdit
        ${'has permissions'}           | ${true}          | ${Namespace.Group}   | ${true}
        ${'has permissions'}           | ${true}          | ${Namespace.Project} | ${false}
        ${'does not have permissions'} | ${false}         | ${Namespace.Group}   | ${false}
        ${'does not have permissions'} | ${false}         | ${Namespace.Project} | ${false}
      `(
        'when user $description and they are viewing an iteration within a $namespaceType',
        ({ canEdit, namespaceType, canEditIteration }) => {
          beforeEach(async () => {
            const mockQueryResponse = {
              [Namespace.Group]: mockGroupIterations,
              [Namespace.Project]: mockProjectIterations,
            }[namespaceType];

            mountComponent({
              props: {
                ...defaultProps,
                canEditIteration,
                namespaceType,
              },
              mockQueryResponse,
            });
            await waitForPromises();
          });

          it(`${canEditIteration ? 'is shown' : 'is hidden'}`, () => {
            expect(wrapper.findComponent(GlDropdown).exists()).toBe(canEdit);
          });
        },
      );
    });
  });
});
