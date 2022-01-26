import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CorpusUpload from 'ee/security_configuration/corpus_management/components/corpus_upload.vue';
import CorpusUploadForm from 'ee/security_configuration/corpus_management/components/corpus_upload_form.vue';

const TEST_PROJECT_FULL_PATH = '/namespace/project';

describe('Corpus Upload', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findCorpusUploadForm = () => wrapper.findComponent(CorpusUploadForm);
  const findNewCorpusButton = () => wrapper.find('[data-testid="new-corpus"]');

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
        canUploadCorpus: true,
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
      expect(findNewCorpusButton().exists()).toBe(true);
      expect(wrapper.element).toMatchSnapshot();
    });

    describe('addCorpus mutation', () => {
      it('gets called when the add button is clicked from the modal', async () => {
        createComponent();
        jest.spyOn(wrapper.vm, 'addCorpus').mockImplementation(() => {});
        await wrapper.vm.$forceUpdate();
        findModal().vm.$emit('primary');
        expect(wrapper.vm.addCorpus).toHaveBeenCalled();
      });
    });

    describe('resetCorpus mutation', () => {
      it('gets called when the cancel button is clicked from the modal', async () => {
        createComponent();
        jest.spyOn(wrapper.vm, 'resetCorpus').mockImplementation(() => {});
        await wrapper.vm.$forceUpdate();
        findModal().vm.$emit('canceled');
        expect(wrapper.vm.resetCorpus).toHaveBeenCalled();
      });

      it('gets called when the upload form triggers a reset', async () => {
        createComponent();
        jest.spyOn(wrapper.vm, 'resetCorpus').mockImplementation(() => {});
        await wrapper.vm.$forceUpdate();
        findCorpusUploadForm().vm.$emit('resetCorpus');
        expect(wrapper.vm.resetCorpus).toHaveBeenCalled();
      });
    });

    describe('uploadCorpus mutation', () => {
      it('gets called when the upload file is clicked from the modal', async () => {
        createComponent();
        jest.spyOn(wrapper.vm, 'beginFileUpload').mockImplementation(() => {});
        await wrapper.vm.$forceUpdate();
        findCorpusUploadForm().vm.$emit('beginFileUpload');
        expect(wrapper.vm.beginFileUpload).toHaveBeenCalled();
      });
    });

    describe('with new uploading disabled', () => {
      it('does not render the upload button', () => {
        createComponent({
          provide: {
            projectFullPath: TEST_PROJECT_FULL_PATH,
            canUploadCorpus: false,
          },
        });

        expect(findNewCorpusButton().exists()).toBe(false);
      });
    });
  });
});
