import { createLocalVue, mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import CorpusUploadForm from 'ee/security_configuration/corpus_management/components/corpus_upload_form.vue';
import createMockApollo from 'helpers/mock_apollo_helper';

const TEST_PROJECT_FULL_PATH = '/namespace/project';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Corpus upload modal', () => {
  let wrapper;

  const findCorpusName = () => wrapper.find('[data-testid="corpus-name"]');
  const findUploadAttachment = () => wrapper.find('[data-testid="upload-attachment-button"]');
  const findUploadCorpus = () => wrapper.find('[data-testid="upload-corpus"]');
  const findUploadStatus = () => wrapper.find('[data-testid="upload-status"]');

  const createComponent = (propsData, options = {}) => {
    wrapper = mount(CorpusUploadForm, {
      localVue,
      propsData,
      apolloProvider: createMockApollo(),
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
            mockedPackages: {
              totalSize: 0,
              data: [],
            },
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
            uploadTimeout: null,
          };
        };

        const props = {
          states: {
            mockedPackages: {
              totalSize: 0,
              data: [],
            },
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
            uploadTimeout: null,
          };
        };

        const props = {
          states: {
            mockedPackages: {
              totalSize: 0,
              data: [],
            },
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
            uploadTimeout: null,
          };
        };

        const props = {
          states: {
            mockedPackages: {
              totalSize: 0,
              data: [],
            },
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
