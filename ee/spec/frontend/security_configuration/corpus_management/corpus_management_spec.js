import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CorpusManagement from 'ee/security_configuration/corpus_management/components/corpus_management.vue';
import CorpusTable from 'ee/security_configuration/corpus_management/components/corpus_table.vue';
import CorpusUpload from 'ee/security_configuration/corpus_management/components/corpus_upload.vue';
import { corpuses } from './mock_data';

const TEST_PROJECT_FULL_PATH = '/namespace/project';
const TEST_CORPUS_HELP_PATH = '/docs/corpus-management';

describe('EE - CorpusManagement', () => {
  let wrapper;

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const defaultMocks = {
      $apollo: {
        loading: false,
      },
    };

    wrapper = mountFn(CorpusManagement, {
      mocks: defaultMocks,
      provide: {
        projectFullPath: TEST_PROJECT_FULL_PATH,
        corpusHelpPath: TEST_CORPUS_HELP_PATH,
      },
      ...options,
    });
  };

  const createComponent = createComponentFactory();

  afterEach(() => {
    wrapper.destroy();
  });

  describe('corpus management', () => {
    describe('when loaded', () => {
      beforeEach(() => {
        const data = () => {
          return { states: { project: { corpuses } } };
        };

        createComponent({ data });
      });

      it('bootstraps and renders the component', () => {
        expect(wrapper.findComponent(CorpusManagement).exists()).toBe(true);
        expect(wrapper.findComponent(CorpusTable).exists()).toBe(true);
        expect(wrapper.findComponent(CorpusUpload).exists()).toBe(true);
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      });

      it('renders the correct header', () => {
        const header = wrapper.findComponent(CorpusManagement).find('header');
        expect(header.element).toMatchSnapshot();
      });
    });

    describe('when loading', () => {
      it('shows loading state when loading', () => {
        const mocks = {
          $apollo: {
            loading: jest.fn().mockResolvedValue(true),
          },
        };
        createComponent({ mocks });
        expect(wrapper.findComponent(CorpusManagement).exists()).toBe(true);
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
        expect(wrapper.findComponent(CorpusTable).exists()).toBe(false);
        expect(wrapper.findComponent(CorpusUpload).exists()).toBe(false);
      });
    });
  });
});
