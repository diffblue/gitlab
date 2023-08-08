import { GlTable } from '@gitlab/ui';
import { merge } from 'lodash';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ProjectList from 'ee/usage_quotas/storage/components/project_list.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import StorageTypeHelpLink from 'ee/usage_quotas/storage/components/storage_type_help_link.vue';
import StorageTypeWarning from 'ee/usage_quotas/storage/components/storage_type_warning.vue';
import { storageTypeHelpPaths } from '~/usage_quotas/storage/constants';
import { projects } from '../mock_data';

let wrapper;

const createComponent = ({ props = {} } = {}) => {
  wrapper = mountExtended(ProjectList, {
    propsData: {
      projects,
      helpLinks: storageTypeHelpPaths,
      isLoading: false,
      sortBy: 'storage',
      sortDesc: true,
      ...props,
    },
  });
};

const createProject = (attrs = {}) => {
  return merge(
    {
      id: 'gid://gitlab/Project/150',
      fullPath: 'frontend-fixtures/gitlab',
      nameWithNamespace: 'Sidney Jones132 / GitLab',
      avatarUrl: null,
      webUrl: 'http://localhost/frontend-fixtures/gitlab',
      name: 'GitLab',
      repositorySizeExcess: 319430.0,
      actualRepositorySizeLimit: 100000.0,
      statistics: {
        commitCount: 0.0,
        storageSize: 1691805.0,
        costFactoredStorageSize: 1691805.0,
        repositorySize: 209710.0,
        lfsObjectsSize: 209720.0,
        containerRegistrySize: 0.0,
        buildArtifactsSize: 1272375.0,
        pipelineArtifactsSize: 0.0,
        packagesSize: 0.0,
        wikiSize: 0.0,
        snippetsSize: 0.0,
        __typename: 'ProjectStatistics',
      },
      __typename: 'Project',
    },
    attrs,
  );
};

const findTable = () => wrapper.findComponent(GlTable);

const storageTypes = [
  { key: 'storage' },
  { key: 'repository' },
  { key: 'snippets' },
  { key: 'buildArtifacts' },
  { key: 'containerRegistry' },
  { key: 'lfsObjects' },
  { key: 'packages' },
  { key: 'wiki' },
];

describe('ProjectList', () => {
  describe('Table header', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each(storageTypes)('$key', ({ key }) => {
      const th = wrapper.findByTestId(`th-${key}`);
      const hasHelpLink = Boolean(storageTypeHelpPaths[key]);

      expect(th.findComponent(StorageTypeHelpLink).exists()).toBe(hasHelpLink);
    });

    it('shows warning icon for container registry type', () => {
      const storageTypeWarning = wrapper
        .findByTestId('th-containerRegistry')
        .findComponent(StorageTypeWarning);

      expect(storageTypeWarning.exists()).toBe(true);
    });
  });

  describe('Project items are rendered', () => {
    describe.each(projects)('$name', (project) => {
      let tableText;

      beforeEach(() => {
        createComponent();
        tableText = findTable().text();
      });

      it('renders project name with namespace', () => {
        const relativeProjectPath = project.nameWithNamespace.split(' / ').slice(1).join(' / ');

        expect(tableText).toContain(relativeProjectPath);
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

  describe('rendering a fork', () => {
    it('renders a fork when the storage size and cost factored storage size match', () => {
      const project = createProject({
        statistics: { storageSize: 200, costFactoredStorageSize: 200 },
      });
      createComponent({ props: { projects: [project] } });

      expect(wrapper.findByText('200 B').exists()).toBe(true);
    });

    it('renders a fork when the storage size and the cost factored storage size differ', () => {
      const project = createProject({
        statistics: { storageSize: 200, costFactoredStorageSize: 100 },
      });
      createComponent({ props: { projects: [project] } });

      const text = findTable()
        .text()
        .replace(/[\s\n]+/g, ' ');
      expect(text).toContain('100 B (of 200 B)');
    });

    it('renders a link to the cost factors for forks documentation', () => {
      const project = createProject({
        statistics: { storageSize: 200, costFactoredStorageSize: 100 },
      });
      createComponent({ props: { projects: [project] } });

      const linkToDocumentation = wrapper.findByRole('link', {
        href: '/help/user/usage_quotas.html#view-project-fork-storage-usage',
      });

      expect(linkToDocumentation.exists()).toBe(true);
    });
  });

  describe('Empty state', () => {
    it('displays empty state message', () => {
      createComponent({ props: { projects: [] } });
      expect(findTable().findAll('tr').at(1).text()).toBe('No projects to display.');
    });
  });
});
