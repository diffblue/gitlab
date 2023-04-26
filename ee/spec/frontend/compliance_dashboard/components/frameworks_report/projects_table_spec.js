import { GlFormCheckbox, GlLabel, GlLoadingIcon, GlTable } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

import { mountExtended } from 'helpers/vue_test_utils_helper';

import {
  createComplianceFrameworksResponse,
  createProjectSetComplianceFrameworkResponse,
} from 'ee_jest/compliance_dashboard/mock_data';
import ProjectsTable from 'ee/compliance_dashboard/components/frameworks_report/projects_table.vue';
import SelectionOperations from 'ee/compliance_dashboard/components/frameworks_report/selection_operations.vue';
import { mapProjects } from 'ee/compliance_dashboard/graphql/mappers';

import setComplianceFrameworkMutation from 'ee/compliance_dashboard/graphql/set_compliance_framework.mutation.graphql';

Vue.use(VueApollo);

describe('ProjectsTable component', () => {
  let wrapper;
  let apolloProvider;
  let projectSetComplianceFrameworkMutation;
  let toastMock;

  const groupPath = 'group-path';
  const rootAncestorPath = 'root-ancestor-path';
  const newGroupComplianceFrameworkPath = 'new-framework-path';

  const COMPLIANCE_FRAMEWORK_COLUMN_IDX = 3;
  const findTable = () => wrapper.findComponent(GlTable);
  const findTableHeaders = () => findTable().findAll('th div');
  const findTableRowData = (idx) => findTable().findAll('tbody > tr').at(idx).findAll('td');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findByTestId('projects-table-empty-state');

  const findSelectAllCheckbox = () => findTableHeaders().at(0).findComponent(GlFormCheckbox);
  const findSelectedRows = () => findTable().findAll('.b-table-row-selected');

  const isIndeterminate = (glFormCheckbox) => glFormCheckbox.vm.$attrs.indeterminate;

  const selectRow = (index) => findTableRowData(index).at(0).trigger('click');

  const createComponent = (props = {}) => {
    projectSetComplianceFrameworkMutation = jest
      .fn()
      .mockResolvedValue(createProjectSetComplianceFrameworkResponse());

    apolloProvider = createMockApollo([
      [setComplianceFrameworkMutation, projectSetComplianceFrameworkMutation],
    ]);

    toastMock = { show: jest.fn() };
    return mountExtended(ProjectsTable, {
      apolloProvider,
      propsData: {
        groupPath,
        rootAncestorPath,
        newGroupComplianceFrameworkPath,
        ...props,
      },
      stubs: {
        FrameworkSelectionBox: {
          name: 'FrameworkSelectionBox',
          template: '<div>add-framework-stub</div>',
        },
      },
      mocks: {
        $toast: toastMock,
      },
      attachTo: document.body,
    });
  };

  describe('default behavior', () => {
    it('renders the loading indicator while loading', () => {
      wrapper = createComponent({ projects: [], isLoading: true });

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findTable().text()).not.toContain('No projects found');
    });

    it('renders the empty state when no projects found', () => {
      wrapper = createComponent({ projects: [], isLoading: false });

      const emptyState = findEmptyState();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(emptyState.exists()).toBe(true);
      expect(emptyState.text()).toBe('No projects found');
    });

    it('has the correct table headers', () => {
      wrapper = createComponent({ projects: [], isLoading: false });
      const headerTexts = findTableHeaders().wrappers.map((h) => h.text());

      expect(headerTexts).toStrictEqual([
        '',
        'Project name',
        'Project path',
        'Compliance framework',
      ]);
    });
  });

  describe('when there are projects', () => {
    const projectsResponse = createComplianceFrameworksResponse({ count: 2 });
    projectsResponse.data.group.projects.nodes[1].complianceFrameworks.nodes = [];

    const projects = mapProjects(projectsResponse.data.group.projects.nodes);

    beforeEach(() => {
      wrapper = createComponent({
        projects,
        isLoading: false,
      });
    });

    describe('correctly handles select all checkbox', () => {
      it('renders select all checkbox in header', () => {
        expect(findSelectAllCheckbox().exists()).toBe(true);
      });

      it('renders empty state when no rows are selected', () => {
        expect(findSelectAllCheckbox().find('input').element.checked).toBe(false);
      });

      it('renders indeterminate state when not all rows are selected', async () => {
        await selectRow(0);
        expect(isIndeterminate(findSelectAllCheckbox())).toBe(true);
      });

      it('does not render indeterminate state when all rows are selected', async () => {
        for (let i = 0; i < projects.length; i += 1) {
          // eslint-disable-next-line no-await-in-loop
          await selectRow(i);
        }

        expect(isIndeterminate(findSelectAllCheckbox())).toBe(false);
      });

      it('renders checked state when all rows are selected', async () => {
        for (let i = 0; i < projects.length; i += 1) {
          // eslint-disable-next-line no-await-in-loop
          await selectRow(i);
        }

        expect(findSelectAllCheckbox().find('input').element.checked).toBe(true);
      });

      it('clears selection when clicking checkbox in indeterminate state', async () => {
        await selectRow(0);

        await findSelectAllCheckbox().find('label').trigger('click');

        expect(findSelectedRows()).toHaveLength(0);
      });

      it('selects all rows', async () => {
        await findSelectAllCheckbox().find('label').trigger('click');

        expect(findSelectedRows()).toHaveLength(projects.length);
      });
    });

    it('passes selection to selection operations component', async () => {
      await selectRow(0);

      expect(wrapper.findComponent(SelectionOperations).props().selection).toHaveLength(1);
      expect(wrapper.findComponent(SelectionOperations).props().selection[0]).toBe(projects[0]);
    });

    it('passes root ancestor path to selection operations component', () => {
      expect(wrapper.findComponent(SelectionOperations).props().rootAncestorPath).toBe(
        rootAncestorPath,
      );
    });

    it.each(Object.keys(projects))('has the correct data for row %s', (idx) => {
      const [, projectName, projectPath, framework] = findTableRowData(idx).wrappers.map((d) =>
        d.text(),
      );

      expect(projectName).toBe('Gitlab Shell');
      expect(projectPath).toBe('gitlab-org/gitlab-shell');
      const expectedFrameworkName =
        projects[idx].complianceFrameworks[0]?.name ?? 'add-framework-stub';
      expect(framework).toContain(expectedFrameworkName);
    });

    function itCallsSetFrameworkMutation(operations) {
      it('calls mutation', () => {
        expect(projectSetComplianceFrameworkMutation).toHaveBeenCalledTimes(operations.length);
        operations.forEach((operation) => {
          expect(projectSetComplianceFrameworkMutation).toHaveBeenCalledWith({
            projectId: operation.projectId,
            frameworkId: operation.frameworkId,
          });
        });
      });

      it('displays toast', async () => {
        await waitForPromises();

        expect(toastMock.show).toHaveBeenCalled();
      });

      it('emits update event', async () => {
        await waitForPromises();

        expect(wrapper.emitted('updated')).toHaveLength(1);
      });

      it('clicking undo in toast reverts changes', async () => {
        await waitForPromises();

        const undoFn = toastMock.show.mock.calls[0][1].action.onClick;

        undoFn();

        expect(projectSetComplianceFrameworkMutation).toHaveBeenCalledTimes(operations.length * 2);
        operations.forEach((operation) => {
          expect(projectSetComplianceFrameworkMutation).toHaveBeenCalledWith(
            expect.objectContaining({
              frameworkId: operation.previousFrameworkId,
              projectId: operation.projectId,
            }),
          );
        });
      });
    }

    describe('when selection operations component emits change event', () => {
      const operations = [
        {
          projectId: 'someId',
          frameworkId: 'framework-id',
          previousFrameworkId: 'previous-framework-id',
        },
        {
          projectId: 'someId-2',
          frameworkId: 'framework-id-2',
          previousFrameworkId: 'previous-framework-id-2',
        },
      ];

      beforeEach(() => {
        wrapper.findComponent(SelectionOperations).vm.$emit('change', operations);
      });

      itCallsSetFrameworkMutation(operations);
    });

    describe('when clicking close sign of framework badge', () => {
      const ROW_WITH_FRAMEWORK_IDX = 0;

      beforeEach(() => {
        findTableRowData(0)
          .at(COMPLIANCE_FRAMEWORK_COLUMN_IDX)
          .findComponent(GlLabel)
          .vm.$emit('close');
      });

      itCallsSetFrameworkMutation([
        {
          projectId: projects[ROW_WITH_FRAMEWORK_IDX].id,
          frameworkId: null,
          previousFrameworkId: projects[ROW_WITH_FRAMEWORK_IDX].complianceFrameworks[0].id,
        },
      ]);

      it('renders loading indicator while loading', () => {
        expect(
          findTableRowData(ROW_WITH_FRAMEWORK_IDX)
            .at(COMPLIANCE_FRAMEWORK_COLUMN_IDX)
            .findComponent(GlLoadingIcon)
            .exists(),
        ).toBe(true);
      });
    });

    describe('when add framework selection is made', () => {
      const NEW_FRAMEWORK_ID = 'new-framework-id';
      const ROW_WITHOUT_FRAMEWORK_IDX = 1;
      beforeEach(() => {
        findTableRowData(ROW_WITHOUT_FRAMEWORK_IDX)
          .at(COMPLIANCE_FRAMEWORK_COLUMN_IDX)
          .findComponent({ name: 'FrameworkSelectionBox' })
          .vm.$emit('select', NEW_FRAMEWORK_ID);
      });

      itCallsSetFrameworkMutation([
        {
          projectId: projects[ROW_WITHOUT_FRAMEWORK_IDX].id,
          frameworkId: NEW_FRAMEWORK_ID,
          previousFrameworkId: null,
        },
      ]);

      it('renders loading indicator while loading', () => {
        expect(
          findTableRowData(ROW_WITHOUT_FRAMEWORK_IDX)
            .at(COMPLIANCE_FRAMEWORK_COLUMN_IDX)
            .findComponent(GlLoadingIcon)
            .exists(),
        ).toBe(true);
      });
    });
  });
});
