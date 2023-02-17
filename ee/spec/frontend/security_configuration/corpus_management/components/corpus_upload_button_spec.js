import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import CorpusUploadButton from 'ee/security_configuration/corpus_management/components/corpus_upload_button.vue';
import CorpusUploadForm from 'ee/security_configuration/corpus_management/components/corpus_upload_form.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

const TEST_PROJECT_FULL_PATH = '/namespace/project';

Vue.use(VueApollo);

describe('Corpus Upload Button', () => {
  let wrapper;
  let uploadStateSpy;
  let uploadCorpusSpy;
  let uploadErrorSpy;
  let resetCorpusSpy;
  let addCorpusSpy;
  let apolloProvider;

  const findModal = () => wrapper.findComponent(GlModal);
  const findCorpusUploadForm = () => wrapper.findComponent(CorpusUploadForm);
  const findNewCorpusButton = () => wrapper.findByTestId('new-corpus');

  const getUploadStateResponse = (data = {}) => ({
    isUploading: false,
    progress: 0,
    cancelSource: null,
    uploadedPackageId: null,
    errors: {
      name: '',
      file: '',
      __typename: 'Errors',
    },
    __typename: 'UploadState',
    ...data,
  });

  const createComponent = ({ canUploadCorpus = true } = {}) => {
    wrapper = shallowMountExtended(CorpusUploadButton, {
      provide: {
        projectFullPath: TEST_PROJECT_FULL_PATH,
        canUploadCorpus,
      },
      apolloProvider,
    });
  };

  const passVariablesToSpy = (spy) => (_, variables) => spy(variables);

  const createApolloProvider = () => {
    uploadStateSpy = jest.fn().mockResolvedValue(getUploadStateResponse());
    uploadCorpusSpy = jest.fn().mockResolvedValue({
      errors: [],
    });
    uploadErrorSpy = jest.fn().mockResolvedValue(null);
    resetCorpusSpy = jest.fn().mockResolvedValue(null);
    addCorpusSpy = jest.fn().mockResolvedValue({
      errors: [],
    });

    const mockResolvers = {
      Query: {
        uploadState: passVariablesToSpy(uploadStateSpy),
      },
      Mutation: {
        uploadCorpus: passVariablesToSpy(uploadCorpusSpy),
        uploadError: passVariablesToSpy(uploadErrorSpy),
        resetCorpus: passVariablesToSpy(resetCorpusSpy),
        addCorpus: passVariablesToSpy(addCorpusSpy),
      },
    };

    apolloProvider = createMockApollo([], mockResolvers);
  };

  beforeEach(() => {
    createApolloProvider();
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

        findModal().vm.$emit('primary');
        await waitForPromises();

        expect(addCorpusSpy).toHaveBeenCalledWith({
          name: CorpusUploadButton.i18n.newCorpus,
          packageId: undefined,
          projectPath: TEST_PROJECT_FULL_PATH,
        });
        expect(wrapper.emitted('corpus-added')).toHaveLength(1);
      });
    });

    describe('resetCorpus mutation', () => {
      it('gets called when the cancel button is clicked from the modal', async () => {
        createComponent();

        findModal().vm.$emit('canceled');
        await waitForPromises();

        expect(resetCorpusSpy).toHaveBeenCalledWith({
          projectPath: TEST_PROJECT_FULL_PATH,
        });
      });

      it('gets called when the upload form triggers a reset', async () => {
        createComponent();

        findCorpusUploadForm().vm.$emit('resetCorpus');
        await waitForPromises();

        expect(resetCorpusSpy).toHaveBeenCalledWith({
          projectPath: TEST_PROJECT_FULL_PATH,
        });
      });
    });

    describe('uploadCorpus mutation', () => {
      it('gets called when the upload file is clicked from the modal', async () => {
        const payload = { name: 'name', files: [{ size: 2 }] };
        createComponent();

        findCorpusUploadForm().vm.$emit('beginFileUpload', payload);
        await waitForPromises();

        expect(uploadCorpusSpy).toHaveBeenCalledWith({
          projectPath: TEST_PROJECT_FULL_PATH,
          ...payload,
        });
      });
    });

    describe('with new uploading disabled', () => {
      it('does not render the upload button', () => {
        createComponent({ canUploadCorpus: false });

        expect(findNewCorpusButton().exists()).toBe(false);
      });
    });

    describe('add button', () => {
      it('is disabled when corpus has not been uploaded', () => {
        uploadStateSpy.mockResolvedValue(
          getUploadStateResponse({
            progress: 0,
            uploadedPackageId: null,
          }),
        );
        createComponent();

        expect(findModal().props('actionPrimary')).toEqual({
          attributes: {
            'data-testid': 'modal-confirm',
            disabled: true,
            variant: 'default',
          },
          text: 'Add',
        });
      });

      it('is disabled when corpus has 100 percent completion, but is still waiting on the server response', () => {
        uploadStateSpy.mockResolvedValue(
          getUploadStateResponse({
            progress: 100,
            uploadedPackageId: null,
          }),
        );
        createComponent();

        expect(findModal().props('actionPrimary')).toEqual({
          attributes: {
            'data-testid': 'modal-confirm',
            disabled: true,
            variant: 'default',
          },
          text: 'Add',
        });
      });

      it('is enabled when corpus has been uploaded', async () => {
        uploadStateSpy.mockResolvedValue(
          getUploadStateResponse({
            progress: 100,
            uploadedPackageId: 1,
          }),
        );

        createComponent();
        await waitForPromises();

        expect(findModal().props('actionPrimary')).toEqual({
          attributes: {
            'data-testid': 'modal-confirm',
            disabled: false,
            variant: 'confirm',
          },
          text: 'Add',
        });
      });
    });
  });
});
