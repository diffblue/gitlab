import { mount } from '@vue/test-utils';
import Actions from 'ee/security_configuration/corpus_management/components/columns/actions.vue';
import CorpusTable from 'ee/security_configuration/corpus_management/components/corpus_table.vue';
import { corpuses } from './mock_data';

const TEST_PROJECT_FULL_PATH = '/namespace/project';

describe('Corpus table', () => {
  let wrapper;

  const createComponentFactory = () => (options = {}) => {
    const defaultProps = {
      corpuses,
    };

    const defaultMocks = {
      $apollo: {
        mutate: jest.fn().mockResolvedValue(),
      },
    };

    wrapper = mount(CorpusTable, {
      propsData: defaultProps,
      provide: {
        projectFullPath: TEST_PROJECT_FULL_PATH,
      },
      mocks: defaultMocks,
      ...options,
    });
  };

  const createComponent = createComponentFactory();

  afterEach(() => {
    wrapper.destroy();
  });

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

    it('triggers the corpus deletion mutation', () => {
      const {
        $apollo: { mutate },
      } = wrapper.vm;

      const actionComponent = wrapper.findComponent(Actions);

      expect(mutate).not.toHaveBeenCalled();
      actionComponent.vm.$emit('delete', 'corpus-name');
      expect(mutate).toHaveBeenCalledTimes(1);
    });

    describe('with no corpuses', () => {
      it('renders the empty state', async () => {
        wrapper.setProps({ corpuses: [] });
        await wrapper.vm.$nextTick();
        expect(wrapper.text()).toContain('Currently, there are no uploaded or generated corpuses');
      });
    });
  });
});
