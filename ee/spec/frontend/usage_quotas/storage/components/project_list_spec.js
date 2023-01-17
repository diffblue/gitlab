import { GlTable } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ProjectList from 'ee/usage_quotas/storage/components/project_list.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import StorageTypeHelpLink from 'ee/usage_quotas/storage/components/storage_type_help_link.vue';
import StorageTypeWarning from 'ee/usage_quotas/storage/components/storage_type_warning.vue';
import { uploadsPopoverContent } from '~/usage_quotas/storage/constants';
import { namespaceContainerRegistryPopoverContent } from 'ee/usage_quotas/storage/constants';
import { projectHelpLinks } from 'jest/usage_quotas/storage/mock_data';
import { projects } from '../mock_data';

let wrapper;

const createComponent = ({ props = {} } = {}) => {
  wrapper = mountExtended(ProjectList, {
    propsData: {
      projects,
      helpLinks: projectHelpLinks,
      isLoading: false,
      ...props,
    },
  });
};

const findTable = () => wrapper.findComponent(GlTable);
const findStorageTypeWarning = (projectId, storageType) =>
  wrapper
    .findByTestId(`cell-${projectId}-storage-type-${storageType}`)
    .findComponent(StorageTypeWarning);

const storageTypes = [
  { key: 'storage' },
  { key: 'repository' },
  { key: 'uploads' },
  { key: 'snippets' },
  { key: 'buildArtifacts' },
  { key: 'containerRegistry' },
  { key: 'lfsObjects' },
  { key: 'packages' },
  { key: 'wiki' },
];

const storageTypesWithPopover = [
  { key: 'container-registry', content: namespaceContainerRegistryPopoverContent },
  { key: 'uploads', content: uploadsPopoverContent },
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

        it.each(storageTypesWithPopover)('show warning icon for $key type', ({ key, content }) => {
          const storageTypeWarning = findStorageTypeWarning(project.id, key);

          expect(storageTypeWarning.exists()).toBe(true);
          expect(storageTypeWarning.props('content')).toBe(content);
        });
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
