import { GlLoadingIcon, GlTableLite } from '@gitlab/ui';

import { mountExtended } from 'helpers/vue_test_utils_helper';

import ProjectsTable from 'ee/compliance_dashboard/components/frameworks_report/projects_table.vue';
import { createComplianceFrameworksResponse } from 'ee_jest/compliance_dashboard/mock_data';
import { mapProjects } from 'ee/compliance_dashboard/graphql/mappers';

describe('ProjectsTable component', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findTableHeaders = () => findTable().findAll('th div');
  const findTableRowData = (idx) => findTable().findAll('tbody > tr').at(idx).findAll('td');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findByTestId('projects-table-empty-state');

  const createComponent = (props = {}) => {
    return mountExtended(ProjectsTable, {
      propsData: {
        ...props,
      },
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

      expect(headerTexts).toStrictEqual(['Project name', 'Project path', 'Compliance framework']);
    });
  });

  describe('when there are projects', () => {
    const projectsResponse = createComplianceFrameworksResponse();
    const projects = mapProjects(projectsResponse.data.group.projects.nodes);

    beforeEach(() => {
      wrapper = createComponent({
        projects,
        isLoading: false,
      });
    });

    it.each(Object.keys(projects))('has the correct data for row %s', (idx) => {
      const [projectName, projectPath, framework] = findTableRowData(idx).wrappers.map((d) =>
        d.text(),
      );

      expect(projectName).toBe('Gitlab Shell');
      expect(projectPath).toBe('gitlab-org/gitlab-shell');
      expect(framework).toContain('some framework');
    });
  });
});
