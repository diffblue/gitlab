import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CorpusUpload from 'ee/security_configuration/corpus_management/components/corpus_upload.vue';

const TEST_PROJECT_FULL_PATH = '/namespace/project';

describe('Corpus Upload', () => {
  let wrapper;

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const defaultProps = { totalSize: 4e8 };
    wrapper = mountFn(CorpusUpload, {
      propsData: defaultProps,
      mocks: {
        states: {
          uploadState: {
            progress: 0,
          },
        },
      },
      provide: {
        projectFullPath: TEST_PROJECT_FULL_PATH,
      },
      ...options,
    });
  };

  const createComponent = createComponentFactory();

  afterEach(() => {
    wrapper.destroy();
  });

  describe('component', () => {
    it('renders header', () => {
      createComponent();
      expect(wrapper.findComponent(GlButton).exists()).toBe(true);
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
