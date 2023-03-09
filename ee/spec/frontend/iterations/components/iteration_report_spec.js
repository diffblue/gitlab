import { GlDropdown, GlEmptyState, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import IterationReport from 'ee/iterations/components/iteration_report.vue';
import IterationReportTabs from 'ee/iterations/components/iteration_report_tabs.vue';
import TimeboxStatusBadge from 'ee/iterations/components/timebox_status_badge.vue';
import deleteIteration from 'ee/iterations/queries/destroy_iteration.mutation.graphql';
import query from 'ee/iterations/queries/iteration.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';
import { getIterationPeriod } from 'ee/iterations/utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { __ } from '~/locale';
import {
  mockIterationNode,
  mockManualIterationNode,
  createMockGroupIterations,
  mockIterationNodeWithoutTitle,
  mockProjectIterations,
} from '../mock_data';

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
    namespaceType: WORKSPACE_GROUP,
  };
  const labelsFetchPath = '/labels.json';

  const findTopbar = () => wrapper.findComponent({ ref: 'topbar' });
  const findHeading = () => wrapper.findComponent({ ref: 'heading' });
  const findDescription = () => wrapper.findComponent({ ref: 'description' });
  const findActionsDropdown = () => wrapper.find('[data-testid="actions-dropdown"]');
  const findDeleteButton = () => wrapper.findByText(__('Delete'));

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const mountComponent = ({
    props = defaultProps,
    mockQueryResponse = createMockGroupIterations(),
    iterationQueryHandler = jest.fn().mockResolvedValue(mockQueryResponse),
    deleteMutationResponse = { data: { iterationDelete: { errors: [] } } },
    deleteMutationMock = jest.fn().mockResolvedValue(deleteMutationResponse),
  } = {}) => {
    Vue.use(VueApollo);
    mockApollo = createMockApollo([
      [query, iterationQueryHandler],
      [deleteIteration, deleteMutationMock],
    ]);

    wrapper = extendedWrapper(
      shallowMount(IterationReport, {
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
          IterationTitle,
        },
      }),
    );
  };

  describe('with mock apollo', () => {
    describe.each([
      [
        WORKSPACE_GROUP,
        'group-name',
        mockIterationNodeWithoutTitle,
        createMockGroupIterations(mockIterationNodeWithoutTitle),
      ],
      [
        WORKSPACE_GROUP,
        'group-name',
        mockIterationNode,
        createMockGroupIterations(mockIterationNode),
      ],
      [WORKSPACE_PROJECT, 'group-name/project-name', mockIterationNode, mockProjectIterations],
    ])(
      'when viewing an iteration in a %s',
      (namespaceType, fullPath, mockIteration, mockIterations) => {
        let iterationQueryHandler;

        beforeEach(() => {
          iterationQueryHandler = jest.fn().mockResolvedValue(mockIterations);

          mountComponent({
            props: {
              namespaceType,
              fullPath,
              iterationId: String(getIdFromGraphQLId(mockIteration.id)),
            },
            iterationQueryHandler,
          });
        });

        it('calls a query with correct parameters', () => {
          expect(iterationQueryHandler).toHaveBeenNthCalledWith(1, {
            fullPath,
            id: mockIteration.id,
            isGroup: namespaceType === WORKSPACE_GROUP,
          });
        });

        it('renders iteration dates optionally with title', async () => {
          await waitForPromises();

          expect(findHeading().text()).toContain(getIterationPeriod(mockIteration));

          if (mockIteration.title) expect(findHeading().text()).toContain(mockIteration.title);
        });
      },
    );
  });

  describe('delete iteration', () => {
    it('does not show delete option when iteration belongs to automatic cadence', async () => {
      mountComponent({ mockQueryResponse: createMockGroupIterations(mockIterationNode) });

      await waitForPromises();

      expect(findDeleteButton().exists()).toBe(false);
    });

    it('shows delete option when iteration belongs to automatic cadence', async () => {
      mountComponent({ mockQueryResponse: createMockGroupIterations(mockManualIterationNode) });

      await waitForPromises();

      expect(findDeleteButton().exists()).toBe(false);
    });

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
      expect(findHeading().exists()).toBe(false);
      expect(findDescription().exists()).toBe(false);
      expect(findActionsDropdown().exists()).toBe(false);
    });
  });

  describe('item loaded', () => {
    describe('user without edit permission', () => {
      beforeEach(async () => {
        mountComponent({
          iterationQueryHandler: jest
            .fn()
            .mockResolvedValue(createMockGroupIterations(mockIterationNode)),
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

      it('shows iteration dates', () => {
        expect(findHeading().text()).toContain(getIterationPeriod(mockIterationNode));
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
          namespaceType: WORKSPACE_GROUP,
        });
      });
    });

    describe('actions dropdown to edit iteration', () => {
      describe.each`
        description                    | canEditIteration | namespaceType        | canEdit
        ${'has permissions'}           | ${true}          | ${WORKSPACE_GROUP}   | ${true}
        ${'has permissions'}           | ${true}          | ${WORKSPACE_PROJECT} | ${false}
        ${'does not have permissions'} | ${false}         | ${WORKSPACE_GROUP}   | ${false}
        ${'does not have permissions'} | ${false}         | ${WORKSPACE_PROJECT} | ${false}
      `(
        'when user $description and they are viewing an iteration within a $namespaceType',
        ({ canEdit, namespaceType, canEditIteration }) => {
          beforeEach(async () => {
            const mockQueryResponse = {
              [WORKSPACE_GROUP]: createMockGroupIterations(mockIterationNode),
              [WORKSPACE_PROJECT]: mockProjectIterations,
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
