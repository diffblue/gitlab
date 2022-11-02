import { GlTable } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import ProjectList from 'ee/usage_quotas/storage/components/project_list.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { projects } from '../mock_data';

let wrapper;

const createComponent = ({ props = {} } = {}) => {
  wrapper = mount(ProjectList, {
    propsData: {
      projects,
      isLoading: false,
      ...props,
    },
  });
};

const findTable = () => wrapper.findComponent(GlTable);

describe('ProjectList', () => {
  describe('Normal state', () => {
    beforeEach(() => {
      createComponent();
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

        it.each([
          'storageSize',
          'repositorySize',
          'uploadsSize',
          'snippetsSize',
          'buildArtifactsSize',
          'containerRegistrySize',
          'lfsObjectsSize',
          'packagesSize',
          'wikiSize',
        ])('%s', (storageType) => {
          const expectedText = numberToHumanSize(project.statistics[storageType], 1);
          expect(tableText).toContain(expectedText);
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
