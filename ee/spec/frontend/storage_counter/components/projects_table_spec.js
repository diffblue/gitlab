import { shallowMount } from '@vue/test-utils';
import Project from 'ee/storage_counter/components/project.vue';
import ProjectsTable from 'ee/storage_counter/components/projects_table.vue';
import { projects } from '../mock_data';

let wrapper;

const createComponent = ({ additionalRepoStorageByNamespace = false } = {}) => {
  wrapper = shallowMount(ProjectsTable, {
    propsData: {
      projects,
      additionalPurchasedStorageSize: 0,
    },
    provide: {
      glFeatures: {
        additionalRepoStorageByNamespace,
      },
    },
  });
};

const findTableRows = () => wrapper.findAll(Project);

describe('Usage Quotas project table component', () => {
  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders regular project rows by default', () => {
    expect(findTableRows()).toHaveLength(3);
  });

  describe('with additional repo storage feature flag ', () => {
    beforeEach(() => {
      createComponent({ additionalRepoStorageByNamespace: true });
    });

    it('renders regular project rows by default', () => {
      expect(findTableRows()).toHaveLength(3);
    });
  });
});
