import { GlTable } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ProjectList from 'ee/usage_quotas/storage/components/project_list.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import StorageTypeHelpLink from 'ee/usage_quotas/storage/components/storage_type_help_link.vue';
import StorageTypeWarning from 'ee/usage_quotas/storage/components/storage_type_warning.vue';
import { projectHelpLinks } from 'jest/usage_quotas/storage/mock_data';
import { projects } from '../mock_data';

let wrapper;

const createComponent = ({ props = {} } = {}) => {
  wrapper = mountExtended(ProjectList, {
    propsData: {
      projects,
      helpLinks: projectHelpLinks,
      isLoading: false,
      sortBy: 'storage',
      sortDesc: true,
      ...props,
    },
  });
};

const findTable = () => wrapper.findComponent(GlTable);

const storageTypes = [
  { key: 'storage' },
  { key: 'repository' },
  { key: 'snippets' },
  { key: 'buildArtifacts' },
  { key: 'pipelineArtifacts' },
  { key: 'containerRegistry' },
  { key: 'lfsObjects' },
  { key: 'packages' },
  { key: 'wiki' },
];

describe('ProjectList', () => {
  describe('Normal state', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('Table header', () => {
      it.each(storageTypes)('$key', ({ key }) => {
        const th = wrapper.findByTestId(`th-${key}`);
        const hasHelpLink = Boolean(projectHelpLinks[key]);

        expect(th.findComponent(StorageTypeHelpLink).exists()).toBe(hasHelpLink);
      });

      it('show warning icon for container registry type', () => {
        const storageTypeWarning = wrapper
          .findByTestId('th-containerRegistry')
          .findComponent(StorageTypeWarning);

        expect(storageTypeWarning.exists()).toBe(true);
      });
    });

    describe('Project items are rendered', () => {
      let tableText;
      beforeEach(() => {
        tableText = findTable().text();
      });

      describe.each(projects)('$name', (project) => {
        it('renders project name with namespace', () => {
          expect(tableText).toContain(project.nameWithNamespace);
        });

        it.each(storageTypes)('$key', ({ key }) => {
          const expectedText = numberToHumanSize(project.statistics[`${key}Size`], 1);
          expect(tableText).toContain(expectedText);
        });
      });

      it.each`
        project        | projectUrlWithUsageQuotas
        ${projects[0]} | ${'http://localhost/frontend-fixtures/twitter/-/usage_quotas'}
        ${projects[1]} | ${'http://localhost/frontend-fixtures/html5-boilerplate/-/usage_quotas'}
        ${projects[2]} | ${'http://localhost/frontend-fixtures/dummy-project/-/usage_quotas'}
      `('renders project link as usage_quotas URL', ({ project, projectUrlWithUsageQuotas }) => {
        createComponent({ props: { projects: [project] } });

        expect(wrapper.findByTestId('project-link').attributes('href')).toBe(
          projectUrlWithUsageQuotas,
        );
      });
    });

    describe('Empty state', () => {
      it('displays empty state message', () => {
        createComponent({ props: { projects: [] } });
        expect(findTable().findAll('tr').at(1).text()).toBe('No projects to display.');
      });
    });
  });
});
