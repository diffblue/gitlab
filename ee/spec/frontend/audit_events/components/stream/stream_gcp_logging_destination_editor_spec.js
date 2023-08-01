import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlForm } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import googleCloudLoggingConfigurationCreate from 'ee/audit_events/graphql/mutations/create_gcp_logging_destination.mutation.graphql';
import googleCloudLoggingConfigurationUpdate from 'ee/audit_events/graphql/mutations/update_gcp_logging_destination.mutation.graphql';
import StreamGcpLoggingDestinationEditor from 'ee/audit_events/components/stream/stream_gcp_logging_destination_editor.vue';
import StreamDeleteModal from 'ee/audit_events/components/stream/stream_delete_modal.vue';
import { AUDIT_STREAMS_NETWORK_ERRORS, ADD_STREAM_EDITOR_I18N } from 'ee/audit_events/constants';
import {
  gcpLoggingDestinationCreateMutationPopulator,
  gcpLoggingDestinationUpdateMutationPopulator,
  groupPath,
  mockGcpLoggingDestinations,
} from '../../mock_data';

jest.mock('~/alert');
Vue.use(VueApollo);

describe('StreamDestinationEditor', () => {
  let wrapper;

  const createComponent = ({
    mountFn = mountExtended,
    props = {},
    apolloHandlers = [
      [
        googleCloudLoggingConfigurationCreate,
        jest.fn().mockResolvedValue(gcpLoggingDestinationCreateMutationPopulator()),
      ],
    ],
  } = {}) => {
    const mockApollo = createMockApollo(apolloHandlers);
    wrapper = mountFn(StreamGcpLoggingDestinationEditor, {
      attachTo: document.body,
      provide: {
        groupPath,
      },
      propsData: {
        ...props,
      },
      apolloProvider: mockApollo,
    });
  };

  const findWarningMessage = () => wrapper.findByTestId('data-warning');
  const findAlertErrors = () => wrapper.findAllByTestId('alert-errors');
  const findDestinationForm = () => wrapper.findComponent(GlForm);
  const findAddStreamBtn = () => wrapper.findByTestId('stream-destination-add-button');
  const findCancelStreamBtn = () => wrapper.findByTestId('stream-destination-cancel-button');
  const findDeleteBtn = () => wrapper.findByTestId('stream-destination-delete-button');
  const findDeleteModal = () => wrapper.findComponent(StreamDeleteModal);

  const findProjectIdFormGroup = () => wrapper.findByTestId('project-id-form-group');
  const findProjectId = () => wrapper.findByTestId('project-id');
  const findClientEmailFormGroup = () => wrapper.findByTestId('client-email-form-group');
  const findClientEmailUrl = () => wrapper.findByTestId('client-email');
  const findLogIdFormGroup = () => wrapper.findByTestId('log-id-form-group');
  const findLogId = () => wrapper.findByTestId('log-id');
  const findPrivateKeyFormGroup = () => wrapper.findByTestId('private-key-form-group');
  const findPrivateKey = () => wrapper.findByTestId('private-key');

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('Group GCP Logging StreamDestinationEditor', () => {
    describe('when initialized', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should render the destinations warning', () => {
        expect(findWarningMessage().props('title')).toBe(ADD_STREAM_EDITOR_I18N.WARNING_TITLE);
      });

      it('should render the destination ProjectId input', () => {
        expect(findProjectIdFormGroup().exists()).toBe(true);
        expect(findProjectId().exists()).toBe(true);
        expect(findProjectId().attributes('placeholder')).toBe(
          ADD_STREAM_EDITOR_I18N.GCP_LOGGING_DESTINATION_PROJECT_ID_PLACEHOLDER,
        );
      });

      it('should render the destination ClientEmail input', () => {
        expect(findClientEmailFormGroup().exists()).toBe(true);
        expect(findClientEmailUrl().exists()).toBe(true);
        expect(findClientEmailUrl().attributes('placeholder')).toBe(
          ADD_STREAM_EDITOR_I18N.GCP_LOGGING_DESTINATION_CLIENT_EMAIL_PLACEHOLDER,
        );
      });

      it('should render the destination IdForm input', () => {
        expect(findLogIdFormGroup().exists()).toBe(true);
        expect(findLogId().exists()).toBe(true);
        expect(findLogId().attributes('placeholder')).toBe(
          ADD_STREAM_EDITOR_I18N.GCP_LOGGING_DESTINATION_LOG_ID_PLACEHOLDER,
        );
      });

      it('should render the destination Private key input', () => {
        expect(findPrivateKeyFormGroup().exists()).toBe(true);
        expect(findPrivateKey().exists()).toBe(true);
      });

      it('does not render the delete button', () => {
        expect(findDeleteBtn().exists()).toBe(false);
      });

      it('renders the add button text', () => {
        expect(findAddStreamBtn().attributes('name')).toBe(ADD_STREAM_EDITOR_I18N.ADD_BUTTON_NAME);
        expect(findAddStreamBtn().text()).toBe(ADD_STREAM_EDITOR_I18N.ADD_BUTTON_TEXT);
      });

      it('disables the add button at first', () => {
        expect(findAddStreamBtn().props('disabled')).toBe(true);
      });
    });

    describe('add destination event', () => {
      it('should emit add event after destination added', async () => {
        createComponent();

        await findProjectId().vm.$emit('input', mockGcpLoggingDestinations[0].googleProjectIdName);
        await findClientEmailUrl().vm.$emit('input', mockGcpLoggingDestinations[0].clientEmail);
        await findLogId().vm.$emit('input', mockGcpLoggingDestinations[0].logIdName);
        await findPrivateKey().vm.$emit('input', mockGcpLoggingDestinations[0].privateKey);

        expect(findAddStreamBtn().props('disabled')).toBe(false);

        await findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
        await waitForPromises();

        expect(findAlertErrors()).toHaveLength(0);
        expect(wrapper.emitted('error')).toBeUndefined();
        expect(wrapper.emitted('added')).toBeDefined();
      });

      it('should not emit add destination event and reports error when server returns error', async () => {
        const errorMsg = 'Destination hosts limit exceeded';
        createComponent({
          apolloHandlers: [
            [
              googleCloudLoggingConfigurationCreate,
              jest.fn().mockResolvedValue(gcpLoggingDestinationCreateMutationPopulator([errorMsg])),
            ],
          ],
        });

        findProjectId().vm.$emit('input', mockGcpLoggingDestinations[0].googleProjectIdName);
        findClientEmailUrl().vm.$emit('input', mockGcpLoggingDestinations[0].clientEmail);
        findLogId().vm.$emit('input', mockGcpLoggingDestinations[0].logIdName);
        findPrivateKey().vm.$emit('input', mockGcpLoggingDestinations[0].privateKey);
        findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
        await waitForPromises();

        expect(findAlertErrors()).toHaveLength(1);
        expect(findAlertErrors().at(0).text()).toBe(errorMsg);
        expect(wrapper.emitted('error')).toBeDefined();
        expect(wrapper.emitted('added')).toBeUndefined();
      });

      it('should not emit add destination event and reports error when network error occurs', async () => {
        const sentryError = new Error('Network error');
        const sentryCaptureExceptionSpy = jest.spyOn(Sentry, 'captureException');
        createComponent({
          apolloHandlers: [
            [googleCloudLoggingConfigurationCreate, jest.fn().mockRejectedValue(sentryError)],
          ],
        });

        findProjectId().vm.$emit('input', mockGcpLoggingDestinations[0].googleProjectIdName);
        findClientEmailUrl().vm.$emit('input', mockGcpLoggingDestinations[0].clientEmail);
        findLogId().vm.$emit('input', mockGcpLoggingDestinations[0].logIdName);
        findPrivateKey().vm.$emit('input', mockGcpLoggingDestinations[0].privateKey);
        findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
        await waitForPromises();

        expect(findAlertErrors()).toHaveLength(1);
        expect(findAlertErrors().at(0).text()).toBe(AUDIT_STREAMS_NETWORK_ERRORS.CREATING_ERROR);
        expect(sentryCaptureExceptionSpy).toHaveBeenCalledWith(sentryError);
        expect(wrapper.emitted('error')).toBeDefined();
        expect(wrapper.emitted('added')).toBeUndefined();
      });
    });

    describe('cancel event', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should emit cancel event correctly', () => {
        findCancelStreamBtn().vm.$emit('click');

        expect(wrapper.emitted('cancel')).toBeDefined();
      });
    });

    describe('when editing an existing destination', () => {
      describe('renders', () => {
        beforeEach(() => {
          createComponent({ props: { item: mockGcpLoggingDestinations[0] } });
        });

        it('the destination fields', () => {
          expect(findProjectId().exists()).toBe(true);
          expect(findProjectId().element.value).toBe(
            mockGcpLoggingDestinations[0].googleProjectIdName,
          );
          expect(findClientEmailUrl().exists()).toBe(true);
          expect(findClientEmailUrl().element.value).toBe(
            mockGcpLoggingDestinations[0].clientEmail,
          );
          expect(findLogId().exists()).toBe(true);
          expect(findLogId().element.value).toBe(mockGcpLoggingDestinations[0].logIdName);
          expect(findPrivateKey().exists()).toBe(true);
          expect(findPrivateKey().element.value).toBe(mockGcpLoggingDestinations[0].privateKey);
        });

        it('the delete button', () => {
          expect(findDeleteBtn().exists()).toBe(true);
        });

        it('renders the save button text', () => {
          expect(findAddStreamBtn().attributes('name')).toBe(
            ADD_STREAM_EDITOR_I18N.SAVE_BUTTON_NAME,
          );
          expect(findAddStreamBtn().text()).toBe(ADD_STREAM_EDITOR_I18N.SAVE_BUTTON_TEXT);
        });

        it('disables the save button at first', () => {
          expect(findAddStreamBtn().props('disabled')).toBe(true);
        });
      });

      it.each`
        name              | findInputFn
        ${'Project ID'}   | ${findProjectId}
        ${'Client Email'} | ${findClientEmailUrl}
        ${'Log ID'}       | ${findLogId}
        ${'Private Key'}  | ${findPrivateKey}
      `('enable the save button when $name is edited', async ({ findInputFn }) => {
        createComponent({ props: { item: mockGcpLoggingDestinations[0] } });

        expect(findAddStreamBtn().props('disabled')).toBe(true);

        await findInputFn().vm.$emit('input', 'test');

        expect(findAddStreamBtn().props('disabled')).toBe(false);
      });

      it('should emit updated event after destination updated', async () => {
        createComponent({
          props: { item: mockGcpLoggingDestinations[0] },
          apolloHandlers: [
            [
              googleCloudLoggingConfigurationUpdate,
              jest.fn().mockResolvedValue(gcpLoggingDestinationUpdateMutationPopulator()),
            ],
          ],
        });

        findProjectId().vm.$emit('input', mockGcpLoggingDestinations[1].googleProjectIdName);
        findClientEmailUrl().vm.$emit('input', mockGcpLoggingDestinations[1].clientEmail);
        findLogId().vm.$emit('input', mockGcpLoggingDestinations[1].logIdName);
        findPrivateKey().vm.$emit('input', mockGcpLoggingDestinations[1].privateKey);
        findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
        await waitForPromises();

        expect(findAlertErrors()).toHaveLength(0);
        expect(wrapper.emitted('error')).toBeUndefined();
        expect(wrapper.emitted('updated')).toBeDefined();
      });

      it('should not emit add destination event and reports error when server returns error', async () => {
        const errorMsg = 'Destination hosts limit exceeded';
        createComponent({
          props: { item: mockGcpLoggingDestinations[0] },
          apolloHandlers: [
            [
              googleCloudLoggingConfigurationUpdate,
              jest.fn().mockResolvedValue(gcpLoggingDestinationUpdateMutationPopulator([errorMsg])),
            ],
          ],
        });

        findProjectId().vm.$emit('input', mockGcpLoggingDestinations[0].googleProjectIdName);
        findClientEmailUrl().vm.$emit('input', mockGcpLoggingDestinations[0].clientEmail);
        findLogId().vm.$emit('input', mockGcpLoggingDestinations[0].logIdName);
        findPrivateKey().vm.$emit('input', mockGcpLoggingDestinations[0].privateKey);
        findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
        await waitForPromises();

        expect(findAlertErrors()).toHaveLength(1);
        expect(findAlertErrors().at(0).text()).toBe(AUDIT_STREAMS_NETWORK_ERRORS.UPDATING_ERROR);
        expect(wrapper.emitted('error')).toBeDefined();
        expect(wrapper.emitted('updated')).toBeUndefined();
      });

      it('should not emit add destination event and reports error when network error occurs', async () => {
        const sentryError = new Error('Network error');
        const sentryCaptureExceptionSpy = jest.spyOn(Sentry, 'captureException');
        createComponent({
          props: { item: mockGcpLoggingDestinations[0] },
          apolloHandlers: [
            [googleCloudLoggingConfigurationUpdate, jest.fn().mockRejectedValue(sentryError)],
          ],
        });

        findProjectId().vm.$emit('input', mockGcpLoggingDestinations[0].googleProjectIdName);
        findClientEmailUrl().vm.$emit('input', mockGcpLoggingDestinations[0].clientEmail);
        findLogId().vm.$emit('input', mockGcpLoggingDestinations[0].logIdName);
        findPrivateKey().vm.$emit('input', mockGcpLoggingDestinations[0].privateKey);
        findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
        await waitForPromises();

        expect(findAlertErrors()).toHaveLength(1);
        expect(findAlertErrors().at(0).text()).toBe(AUDIT_STREAMS_NETWORK_ERRORS.UPDATING_ERROR);
        expect(sentryCaptureExceptionSpy).toHaveBeenCalledWith(sentryError);
        expect(wrapper.emitted('error')).toBeDefined();
        expect(wrapper.emitted('updated')).toBeUndefined();
      });
    });

    describe('deleting', () => {
      beforeEach(() => {
        createComponent({ props: { item: mockGcpLoggingDestinations[0] } });
      });

      it('should emit deleted on success operation', async () => {
        const deleteButton = findDeleteBtn();
        await deleteButton.trigger('click');
        await findDeleteModal().vm.$emit('deleting');

        expect(deleteButton.props('loading')).toBe(true);

        await findDeleteModal().vm.$emit('delete');

        expect(deleteButton.props('loading')).toBe(false);
        expect(wrapper.emitted('deleted')).toEqual([[mockGcpLoggingDestinations[0].id]]);
      });

      it('shows the alert for the error', () => {
        const errorMsg = 'An error occurred';
        findDeleteModal().vm.$emit('error', errorMsg);

        expect(createAlert).toHaveBeenCalledWith({
          message: AUDIT_STREAMS_NETWORK_ERRORS.DELETING_ERROR,
          captureError: true,
          error: errorMsg,
        });
      });
    });

    it('passes actual newlines when these are used in the private key input', async () => {
      const mutationMock = jest
        .fn()
        .mockResolvedValue(gcpLoggingDestinationCreateMutationPopulator());
      createComponent({
        apolloHandlers: [[googleCloudLoggingConfigurationCreate, mutationMock]],
      });

      await findPrivateKey().setValue('\\ntest\\n');
      await findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });

      expect(mutationMock).toHaveBeenCalledWith(
        expect.objectContaining({
          privateKey: '\ntest\n',
        }),
      );
    });
  });
});
