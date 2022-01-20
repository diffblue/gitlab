import { mount } from '@vue/test-utils';
import CorpusUploadForm from 'ee/security_configuration/corpus_management/components/corpus_upload_form.vue';

const TEST_PROJECT_FULL_PATH = '/namespace/project';

describe('Corpus upload modal', () => {
  let wrapper;

  const findCorpusName = () => wrapper.find('[data-testid="corpus-name"]');
  const findUploadAttachment = () => wrapper.find('[data-testid="upload-attachment-button"]');
  const findUploadCorpus = () => wrapper.find('[data-testid="upload-corpus"]');
  const findUploadStatus = () => wrapper.find('[data-testid="upload-status"]');
  const findFileInput = () => wrapper.findComponent({ ref: 'fileUpload' });
  const findCancelButton = () => wrapper.find('[data-testid="cancel-upload"]');

  const createComponent = (propsData, options = {}) => {
    wrapper = mount(CorpusUploadForm, {
      propsData,
      provide: {
        projectFullPath: TEST_PROJECT_FULL_PATH,
      },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('corpus modal', () => {
    describe('initial state', () => {
      beforeEach(() => {
        const data = () => {
          return {
            attachmentName: '',
            corpusName: '',
            files: [],
            uploadTimeout: null,
          };
        };

        const props = {
          states: {
            uploadState: {
              isUploading: false,
              progress: 0,
            },
          },
        };

        createComponent(props, { data });
      });

      it('shows empty name field', () => {
        expect(findCorpusName().element.value).toBe('');
      });

      it('shows the choose file button', () => {
        expect(findUploadAttachment().exists()).toBe(true);
      });

      it('does not show the upload corpus button', () => {
        expect(findUploadCorpus().exists()).toBe(false);
      });

      it('does not show the upload progress', () => {
        expect(findUploadStatus().exists()).toBe(false);
      });

      describe('selecting a file', () => {
        it('transitions to selected state', async () => {
          jest.spyOn(wrapper.vm, 'onFileUploadChange').mockImplementation(() => {});
          await wrapper.vm.$forceUpdate();
          findFileInput().trigger('change');
          expect(wrapper.vm.onFileUploadChange).toHaveBeenCalled();
        });
      });
    });

    describe('file selected state', () => {
      const attachmentName = 'corpus.zip';
      const corpusName = 'User entered name';

      beforeEach(() => {
        const data = () => {
          return {
            attachmentName,
            corpusName,
            files: [attachmentName],
          };
        };

        const props = {
          states: {
            uploadState: {
              isUploading: false,
              progress: 0,
            },
          },
        };

        createComponent(props, { data });
      });

      it('shows name field', () => {
        expect(findCorpusName().element.value).toBe(corpusName);
      });

      it('shows the choose file button', () => {
        expect(findUploadAttachment().exists()).toBe(true);
      });

      it('shows the upload corpus button', () => {
        expect(findUploadCorpus().exists()).toBe(true);
      });

      it('does not show the upload progress', () => {
        expect(findUploadStatus().exists()).toBe(false);
      });

      describe('clicking upload file', () => {
        it('begins the file upload', async () => {
          jest.spyOn(wrapper.vm, 'beginFileUpload').mockImplementation(() => {});
          await wrapper.vm.$forceUpdate();
          findUploadCorpus().trigger('click');
          expect(wrapper.vm.beginFileUpload).toHaveBeenCalled();
        });
      });
    });

    describe('uploading state', () => {
      const attachmentName = 'corpus.zip';
      const corpusName = 'User entered name';

      beforeEach(() => {
        const data = () => {
          return {
            attachmentName,
            corpusName,
            files: [attachmentName],
          };
        };

        const props = {
          states: {
            uploadState: {
              isUploading: true,
              progress: 25,
            },
          },
        };

        createComponent(props, { data });
      });

      it('shows name field', () => {
        expect(findCorpusName().element.value).toBe(corpusName);
      });

      it('shows the choose file button as disabled', () => {
        expect(findUploadAttachment().exists()).toBe(true);
        expect(findUploadAttachment().attributes('disabled')).toBe('disabled');
      });

      it('does not show the upload corpus button', () => {
        expect(findUploadCorpus().exists()).toBe(false);
      });

      it('does show the upload progress', () => {
        expect(findUploadStatus().exists()).toBe(true);
        expect(findUploadStatus().element).toMatchSnapshot();
      });

      describe('clicking cancel button', () => {
        it('emits the reset corpus event', () => {
          findCancelButton().trigger('click');
          expect(wrapper.emitted().resetCorpus).toBeTruthy();
        });
      });
    });

    describe('file uploaded state', () => {
      const attachmentName = 'corpus.zip';
      const corpusName = 'User entered name';

      beforeEach(() => {
        const data = () => {
          return {
            attachmentName,
            corpusName,
            files: [attachmentName],
          };
        };

        const props = {
          states: {
            uploadState: {
              isUploading: false,
              progress: 100,
            },
          },
        };

        createComponent(props, { data });
      });

      it('shows name field', () => {
        expect(findCorpusName().element.value).toBe(corpusName);
      });

      it('does not show the choose file button', () => {
        expect(findUploadAttachment().exists()).toBe(false);
      });

      it('does not show the upload corpus button', () => {
        expect(findUploadCorpus().exists()).toBe(false);
      });

      it('does not show the upload progress', () => {
        expect(findUploadStatus().exists()).toBe(false);
      });
    });
  });
});
