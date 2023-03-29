import { GlFormCheckbox, GlLoadingIcon, GlTable } from '@gitlab/ui';

import { mountExtended } from 'helpers/vue_test_utils_helper';

import { createComplianceFrameworksResponse } from 'ee_jest/compliance_dashboard/mock_data';
import ProjectsTable from 'ee/compliance_dashboard/components/frameworks_report/projects_table.vue';
import SelectionOperations from 'ee/compliance_dashboard/components/frameworks_report/selection_operations.vue';
import { mapProjects } from 'ee/compliance_dashboard/graphql/mappers';

describe('ProjectsTable component', () => {
  let wrapper;

  const groupPath = 'group-path';
  const newGroupComplianceFrameworkPath = 'new-framework-path';

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
    return mountExtended(ProjectsTable, {
      propsData: {
        groupPath,
        newGroupComplianceFrameworkPath,
        ...props,
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

      it('renders empty state when no rows are selected', async () => {
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

    it.each(Object.keys(projects))('has the correct data for row %s', (idx) => {
      const [, projectName, projectPath, framework] = findTableRowData(idx).wrappers.map((d) =>
        d.text(),
      );

      expect(projectName).toBe('Gitlab Shell');
      expect(projectPath).toBe('gitlab-org/gitlab-shell');
      expect(framework).toContain('some framework');
    });
  });
});
