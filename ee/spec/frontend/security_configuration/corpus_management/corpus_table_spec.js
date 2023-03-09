import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Actions from 'ee/security_configuration/corpus_management/components/columns/actions.vue';
import CorpusTable from 'ee/security_configuration/corpus_management/components/corpus_table.vue';
import { corpuses } from './mock_data';

const TEST_PROJECT_FULL_PATH = '/namespace/project';

const CORPUS = {
  package: {
    id: 1,
  },
};

describe('Corpus table', () => {
  let wrapper;

  const createComponentFactory = () => (options = {}) => {
    const defaultProps = {
      corpuses,
    };

    wrapper = mount(CorpusTable, {
      propsData: defaultProps,
      provide: {
        projectFullPath: TEST_PROJECT_FULL_PATH,
        canReadCorpus: true,
        canDestroyCorpus: true,
      },
      ...options,
    });
  };

  const createComponent = createComponentFactory();

  describe('corpus management', () => {
    beforeEach(() => {
      createComponent();
    });

    it('bootstraps and renders the component', () => {
      expect(wrapper.findComponent(CorpusTable).exists()).toBe(true);
    });

    it('renders with the correct columns', () => {
      const columnHeaders = wrapper.findComponent(CorpusTable).find('thead tr');
      expect(columnHeaders.element).toMatchSnapshot();
    });

    it('emits the delete event', () => {
      const actionComponent = wrapper.findComponent(Actions);
      actionComponent.vm.$emit('delete', CORPUS);
      expect(wrapper.emitted('delete')).toHaveLength(1);
      expect(wrapper.emitted('delete')[0][0]).toEqual(CORPUS.package.id);
    });

    describe('with no corpuses', () => {
      it('renders the empty state', async () => {
        wrapper.setProps({ corpuses: [] });
        await nextTick();
        expect(wrapper.text()).toContain('Currently, there are no uploaded or generated corpuses');
      });
    });
  });
});
