import { GlButton, GlCollapsibleListbox } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  createComplianceFrameworksResponse,
  createProjectSetComplianceFrameworkResponse,
} from 'ee_jest/compliance_dashboard/mock_data';

import { validFetchResponse as getComplianceFrameworksResponse } from 'ee_jest/groups/settings/compliance_frameworks/mock_data';
import SelectionOperations from 'ee/compliance_dashboard/components/frameworks_report/selection_operations.vue';

import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';
import setComplianceFrameworkMutation from 'ee/compliance_dashboard/graphql/set_compliance_framework.mutation.graphql';

Vue.use(VueApollo);
describe('SelectionOperations component', () => {
  let wrapper;
  let apolloProvider;
  let projectSetComplianceFrameworkMutation;
  let toastMock;

  const findOperationDropdown = () =>
    wrapper
      .findAllComponents(GlCollapsibleListbox)
      .wrappers.find((w) => w.text().includes(SelectionOperations.i18n.dropdownActionPlaceholder));

  const findFrameworkSelectionDropdown = () =>
    wrapper
      .findAllComponents(GlCollapsibleListbox)
      .wrappers.find((w) =>
        w.text().includes(SelectionOperations.i18n.frameworksDropdownPlaceholder),
      );

  const select = (glDropdown, value) => {
    glDropdown.vm.$emit(GlCollapsibleListbox.model.event, value);
    return nextTick();
  };

  const createComponent = ({ props }) => {
    projectSetComplianceFrameworkMutation = jest
      .fn()
      .mockResolvedValue(createProjectSetComplianceFrameworkResponse());

    apolloProvider = createMockApollo(
      [
        [setComplianceFrameworkMutation, projectSetComplianceFrameworkMutation],
        [getComplianceFrameworkQuery, () => getComplianceFrameworksResponse],
      ],
      {
        Query: {},
        Mutation: {
          projectSetComplianceFramework: projectSetComplianceFrameworkMutation,
        },
      },
    );

    toastMock = { show: jest.fn() };
    wrapper = mount(SelectionOperations, {
      apolloProvider,
      propsData: {
        groupPath: 'group-path',
        newGroupComplianceFrameworkPath: 'new-framework-path',
        ...props,
      },
      mocks: {
        $toast: toastMock,
      },
    });
  };

  describe('when selection is empty', () => {
    beforeEach(() => {
      createComponent({ props: { selection: [] } });
    });

    it('operation dropdown is disabled', () => {
      expect(findOperationDropdown().props('disabled')).toBe(true);
    });

    it('framework selection dropdown is not available', () => {
      expect(findFrameworkSelectionDropdown()).toBe(undefined);
    });

    it('displays correct text', () => {
      expect(wrapper.text()).toContain('0 selected');
    });
  });

  describe('when selection is provided', () => {
    const COUNT = 2;
    const complianceFrameworkResponse = createComplianceFrameworksResponse({ count: COUNT });
    const projects = complianceFrameworkResponse.data.group.projects.nodes;

    beforeEach(() => {
      createComponent({ props: { selection: projects } });
    });

    it('operation dropdown is enabled', () => {
      expect(findOperationDropdown().props('disabled')).toBe(false);
    });

    describe('when selecting remove operation', () => {
      const findRemoveButton = () =>
        wrapper.findAllComponents(GlButton).wrappers.find((w) => w.text() === 'Remove');

      beforeEach(() =>
        select(findOperationDropdown(), SelectionOperations.operations.REMOVE_OPERATION),
      );

      it('renders remove button', () => {
        expect(findRemoveButton().exists()).toBe(true);
      });

      it('framework selection dropdown is not available', () => {
        expect(findFrameworkSelectionDropdown()).toBe(undefined);
      });

      it('clicking remove button calls mutation', async () => {
        await findRemoveButton().vm.$emit('click');
        expect(projectSetComplianceFrameworkMutation).toHaveBeenCalledTimes(COUNT);
        projects.forEach((p) => {
          expect(projectSetComplianceFrameworkMutation).toHaveBeenCalledWith(
            expect.objectContaining({
              frameworkId: null,
              projectId: p.id,
            }),
          );
        });
      });
    });

    describe('when selecting apply operation', () => {
      const findApplyButton = () =>
        wrapper.findAllComponents(GlButton).wrappers.find((w) => w.text() === 'Apply');

      beforeEach(() =>
        select(findOperationDropdown(), SelectionOperations.operations.APPLY_OPERATION),
      );

      it('renders apply button, disabled by default', () => {
        expect(findApplyButton().exists()).toBe(true);
        expect(findApplyButton().props('disabled')).toBe(true);
      });

      it('framework selection dropdown is available', () => {
        expect(findFrameworkSelectionDropdown().exists()).toBe(true);
      });

      describe('when selecting framework', () => {
        const SELECTED_FRAMEWORK =
          getComplianceFrameworksResponse.data.namespace.complianceFrameworks.nodes[1].id;

        beforeEach(() => select(findFrameworkSelectionDropdown(), SELECTED_FRAMEWORK));

        it('enables apply button when framework is selected', async () => {
          expect(findApplyButton().props('disabled')).toBe(false);
        });

        it('clicking cancel button resets state', async () => {
          wrapper
            .findAllComponents(GlButton)
            .wrappers.find((w) => w.text() === 'Cancel')
            .vm.$emit('click');

          await nextTick();

          expect(findOperationDropdown().props(GlCollapsibleListbox.model.prop)).toBe(null);
          expect(findFrameworkSelectionDropdown()).toBe(undefined);
          expect(findApplyButton().exists()).toBe(true);
          expect(findApplyButton().props('disabled')).toBe(true);
        });

        describe('when clicking apply button calls mutation', () => {
          beforeEach(() => findApplyButton().vm.$emit('click'));

          it('calls mutation', async () => {
            expect(projectSetComplianceFrameworkMutation).toHaveBeenCalledTimes(COUNT);
            projects.forEach((p) => {
              expect(projectSetComplianceFrameworkMutation).toHaveBeenCalledWith(
                expect.objectContaining({
                  frameworkId: SELECTED_FRAMEWORK,
                  projectId: p.id,
                }),
              );
            });
          });

          it('displays toast', async () => {
            await waitForPromises();
            expect(toastMock.show).toHaveBeenCalled();
          });

          it('clicking undo in toast reverts changes', async () => {
            await waitForPromises();
            const undoFn = toastMock.show.mock.calls[0][1].action.onClick;

            undoFn();

            expect(projectSetComplianceFrameworkMutation).toHaveBeenCalledTimes(COUNT * 2);
            projects.forEach((p) => {
              expect(projectSetComplianceFrameworkMutation).toHaveBeenCalledWith(
                expect.objectContaining({
                  frameworkId: p.complianceFrameworks.nodes[0].id,
                  projectId: p.id,
                }),
              );
            });
          });
        });
      });
    });

    it('displays correct text', () => {
      expect(wrapper.text()).toContain(`${COUNT} selected`);
    });
  });
});
