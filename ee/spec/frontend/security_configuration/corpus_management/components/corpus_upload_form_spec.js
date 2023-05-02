import { mountExtended } from 'helpers/vue_test_utils_helper';
import CorpusUploadForm from 'ee/security_configuration/corpus_management/components/corpus_upload_form.vue';
import { I18N } from 'ee/security_configuration/corpus_management/constants';

const TEST_PROJECT_FULL_PATH = '/namespace/project';

describe('Corpus upload modal', () => {
  let wrapper;

  const findCorpusName = () => wrapper.findByTestId('corpus-name');
  const findUploadAttachment = () => wrapper.findByTestId('upload-attachment-button');
  const findUploadCorpus = () => wrapper.findByTestId('upload-corpus');
  const findUploadStatus = () => wrapper.findByTestId('upload-status');
  const findFileInput = () => wrapper.findComponent({ ref: 'fileUpload' });
  const findCancelButton = () => wrapper.findByTestId('cancel-upload');
  const findNameErrorMsg = () => wrapper.findByText(I18N.invalidName);
  const findFileErrorMsg = () => wrapper.findByText(I18N.fileTooLarge);

  const createComponent = (propsData, options = {}) => {
    wrapper = mountExtended(CorpusUploadForm, {
      propsData,
      provide: {
        projectFullPath: TEST_PROJECT_FULL_PATH,
      },
      ...options,
    });
  };

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
            isUploading: false,
            progress: 0,
            errors: {
              name: '',
              file: '',
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
            isUploading: false,
            progress: 0,
            errors: {
              name: '',
              file: '',
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
            isUploading: true,
            progress: 25,
            errors: {
              name: '',
              file: '',
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
        expect(findUploadAttachment().attributes('disabled')).toBeDefined();
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
          expect(wrapper.emitted().resetCorpus).toEqual([[]]);
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
            isUploading: false,
            progress: 100,
            errors: {
              name: '',
              file: '',
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

    describe('error states', () => {
      describe('invalid corpus name', () => {
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
              isUploading: false,
              progress: 0,
              errors: {
                name: I18N.invalidName,
                file: '',
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

        it('shows corpus name invalid', () => {
          expect(findNameErrorMsg().exists()).toBe(true);
        });
      });

      describe('file too large', () => {
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
              isUploading: false,
              progress: 0,
              errors: {
                name: '',
                file: I18N.fileTooLarge,
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

        it('shows corpus size too large', () => {
          expect(findFileErrorMsg().exists()).toBe(true);
        });
      });

      describe('blank corpus name', () => {
        const attachmentName = 'corpus.zip';
        const corpusName = '';

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
              isUploading: false,
              progress: 0,
              errors: {
                name: '',
                file: '',
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

        it('shows the upload corpus button as disabled', () => {
          expect(findUploadCorpus().exists()).toBe(true);
          expect(findUploadCorpus().attributes('disabled')).toBeDefined();
        });

        it('does not show the upload progress', () => {
          expect(findUploadStatus().exists()).toBe(false);
        });

        it('does not show name format and file error messages', () => {
          expect(findFileErrorMsg().exists()).toBe(false);
          expect(findNameErrorMsg().exists()).toBe(false);
        });
      });
    });
  });
});
