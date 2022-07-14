import VueApollo from 'vue-apollo';
import { createLocalVue } from '@vue/test-utils';
import { GlButton, GlFormCheckbox, GlForm, GlTableLite } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { sprintf } from '~/locale';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  shallowMountExtended,
  mountExtended,
  extendedWrapper,
} from 'helpers/vue_test_utils_helper';
import externalAuditEventDestinationCreate from 'ee/audit_events/graphql/create_external_destination.mutation.graphql';
import externalAuditEventDestinationHeaderCreate from 'ee/audit_events/graphql/create_external_destination_header.mutation.graphql';
import deleteExternalDestination from 'ee/audit_events/graphql/delete_external_destination.mutation.graphql';
import StreamDestinationEditor from 'ee/audit_events/components/stream/stream_destination_editor.vue';
import { AUDIT_STREAMS_NETWORK_ERRORS, ADD_STREAM_EDITOR_I18N } from 'ee/audit_events/constants';
import {
  destinationCreateMutationPopulator,
  destinationDeleteMutationPopulator,
  destinationHeaderCreateMutationPopulator,
  groupPath,
} from '../../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('StreamDestinationEditor', () => {
  let wrapper;

  const maxHeaders = 3;

  const createComponent = (
    mountFn = shallowMountExtended,
    provide = {},
    apolloHandlers = [
      [
        externalAuditEventDestinationCreate,
        jest.fn().mockResolvedValue(destinationCreateMutationPopulator()),
      ],
    ],
  ) => {
    const mockApollo = createMockApollo(apolloHandlers);
    wrapper = mountFn(StreamDestinationEditor, {
      provide: {
        groupPath,
        showStreamsHeaders: false,
        maxHeaders,
        ...provide,
      },
      apolloProvider: mockApollo,
      localVue,
    });
  };

  const findWarningMessage = () => wrapper.findByTestId('data-warning');
  const findAlertErrors = () => wrapper.findAllByTestId('alert-errors');
  const findDestinationForm = () => wrapper.findComponent(GlForm);
  const findHeadersTable = () => wrapper.findComponent(GlTableLite);
  const findMaximumHeadersText = () => wrapper.findByTestId('maximum-headers').text();
  const findAddBtn = () => wrapper.findByTestId('stream-destination-add-button');
  const findCancelBtn = () => wrapper.findByTestId('stream-destination-cancel-button');

  const findDestinationUrlFormGroup = () => wrapper.findByTestId('destination-url-form-group');
  const findDestinationUrl = () => wrapper.findByTestId('destination-url');

  const findHeadersRows = () => findHeadersTable().find('tbody').findAll('tr');
  const findHeadersHeaderCell = (tdIdx) =>
    findHeadersTable().find('thead tr').findAll('th').at(tdIdx);
  const findHeadersCell = (trIdx, tdIdx) => findHeadersRows().at(trIdx).findAll('td').at(tdIdx);
  const findHeaderCheckbox = (trIdx) => findHeadersRows().at(trIdx).findComponent(GlFormCheckbox);
  const findHeaderDeleteBtn = (trIdx) => findHeadersRows().at(trIdx).findComponent(GlButton);
  const findHeaderNameInput = (trIdx) =>
    extendedWrapper(findHeadersRows().at(trIdx)).findByTestId('header-name-input');
  const findHeaderValueInput = (trIdx) =>
    extendedWrapper(findHeadersRows().at(trIdx)).findByTestId('header-value-input');

  const setHeaderNameInput = (trIdx, name) => findHeaderNameInput(trIdx).setValue(name);
  const setHeaderValueInput = (trIdx, value) => findHeaderValueInput(trIdx).setValue(value);

  const setHeadersRowData = async (trIdx, { name, value }) => {
    await setHeaderNameInput(trIdx, name);
    await setHeaderValueInput(trIdx, value);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when initialized', () => {
    describe('destinations URL', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should render the destinations warning', () => {
        expect(findWarningMessage().props('title')).toBe(ADD_STREAM_EDITOR_I18N.WARNING_TITLE);
        expect(findWarningMessage().text()).toBe(ADD_STREAM_EDITOR_I18N.WARNING_CONTENT);
      });

      it('should render the destination URL input', () => {
        expect(findDestinationUrlFormGroup().exists()).toBe(true);
        expect(findDestinationUrl().attributes('placeholder')).toBe(
          ADD_STREAM_EDITOR_I18N.DESTINATION_URL_PLACEHOLDER,
        );
      });
    });

    describe('HTTP headers', () => {
      beforeEach(() => {
        createComponent(mountExtended, { showStreamsHeaders: true });
      });

      it('should render the table', () => {
        expect(findHeadersRows()).toHaveLength(1);

        expect(findHeadersHeaderCell(0).text()).toBe(
          ADD_STREAM_EDITOR_I18N.TABLE_COLUMN_NAME_LABEL,
        );
        expect(findHeadersHeaderCell(1).text()).toBe(
          ADD_STREAM_EDITOR_I18N.TABLE_COLUMN_VALUE_LABEL,
        );
        expect(findHeadersHeaderCell(2).text()).toBe(
          ADD_STREAM_EDITOR_I18N.TABLE_COLUMN_ACTIVE_LABEL,
        );
        expect(findHeadersHeaderCell(3).text()).toBe('');

        expect(findHeaderNameInput(0).attributes('placeholder')).toBe(
          ADD_STREAM_EDITOR_I18N.HEADER_INPUT_PLACEHOLDER,
        );
        expect(findHeaderValueInput(0).attributes('placeholder')).toBe(
          ADD_STREAM_EDITOR_I18N.VALUE_INPUT_PLACEHOLDER,
        );
        expect(findHeaderCheckbox(0).find('input').attributes('disabled')).toBe('disabled');
        expect(findHeaderDeleteBtn(0).exists()).toBe(true);
      });
    });
  });

  describe('add destination event without headers', () => {
    it('should emit add event after destination added', async () => {
      createComponent(shallowMountExtended, {}, [
        [
          externalAuditEventDestinationCreate,
          jest.fn().mockResolvedValue(destinationCreateMutationPopulator()),
        ],
      ]);

      findDestinationUrl().vm.$emit('input', 'https://example.test');
      findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
      await waitForPromises();

      expect(findAlertErrors()).toHaveLength(0);
      expect(wrapper.emitted('added')).toBeDefined();
    });

    it('should not emit add destination event and reports error when server returns error', async () => {
      const errorMsg = 'Destination hosts limit exceeded';
      createComponent(shallowMountExtended, {}, [
        [
          externalAuditEventDestinationCreate,
          jest.fn().mockResolvedValue(destinationCreateMutationPopulator([errorMsg])),
        ],
      ]);

      findDestinationUrl().vm.$emit('input', 'https://example.test');
      findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
      await waitForPromises();

      expect(findAlertErrors()).toHaveLength(1);
      expect(findAlertErrors().at(0).text()).toBe(errorMsg);
      expect(wrapper.emitted('added')).not.toBeDefined();
    });

    it('should not emit add destination event and reports error when network error occurs', async () => {
      const sentryError = new Error('Network error');
      const sentryCaptureExceptionSpy = jest.spyOn(Sentry, 'captureException');
      createComponent(shallowMountExtended, {}, [
        [externalAuditEventDestinationCreate, jest.fn().mockRejectedValue(sentryError)],
      ]);

      findDestinationUrl().vm.$emit('input', 'https://example.test');
      findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
      await waitForPromises();

      expect(findAlertErrors()).toHaveLength(1);
      expect(findAlertErrors().at(0).text()).toBe(AUDIT_STREAMS_NETWORK_ERRORS.CREATING_ERROR);
      expect(sentryCaptureExceptionSpy).toHaveBeenCalledWith(sentryError);
      expect(wrapper.emitted('added')).not.toBeDefined();
    });
  });

  describe('add destination event with headers', () => {
    it('should emit add event after destination and headers are added', async () => {
      createComponent(mountExtended, { showStreamsHeaders: true }, [
        [
          externalAuditEventDestinationCreate,
          jest.fn().mockResolvedValue(destinationCreateMutationPopulator()),
        ],
        [
          externalAuditEventDestinationHeaderCreate,
          jest.fn().mockResolvedValue(destinationHeaderCreateMutationPopulator()),
        ],
      ]);

      findDestinationUrl().vm.$emit('input', 'https://example.test');
      await setHeadersRowData(0, { name: 'row header', value: 'row value' });
      await setHeadersRowData(1, { name: 'row header 1', value: 'row value 1' });
      findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
      await waitForPromises();

      expect(findAlertErrors()).toHaveLength(0);
      expect(wrapper.emitted('added')).toBeDefined();
    });

    it('should ignore empty headers and emit add event after destination and headers are added', async () => {
      const headerCreateSpy = jest
        .fn()
        .mockResolvedValue(destinationHeaderCreateMutationPopulator());

      createComponent(mountExtended, { showStreamsHeaders: true }, [
        [
          externalAuditEventDestinationCreate,
          jest.fn().mockResolvedValue(destinationCreateMutationPopulator()),
        ],
        [externalAuditEventDestinationHeaderCreate, headerCreateSpy],
      ]);

      findDestinationUrl().vm.$emit('input', 'https://example.test');
      await setHeadersRowData(0, { name: 'row header', value: 'row value' });
      await setHeadersRowData(1, { name: '', value: '' });
      findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
      await waitForPromises();

      expect(findAlertErrors()).toHaveLength(0);
      expect(headerCreateSpy).toHaveBeenCalledTimes(1);
      expect(headerCreateSpy).toHaveBeenCalledWith({
        destinationId: 'test-create-id',
        key: 'row header',
        value: 'row value',
      });
      expect(wrapper.emitted('added')).toBeDefined();
    });

    it('should not emit add destination event and reports error when server returns error while adding headers', async () => {
      const errorMsg = 'Destination hosts limit exceeded';
      createComponent(mountExtended, { showStreamsHeaders: true }, [
        [
          externalAuditEventDestinationCreate,
          jest.fn().mockResolvedValue(destinationCreateMutationPopulator()),
        ],
        [
          externalAuditEventDestinationHeaderCreate,
          jest
            .fn()
            .mockResolvedValueOnce(destinationHeaderCreateMutationPopulator())
            .mockResolvedValue(destinationHeaderCreateMutationPopulator([errorMsg])),
        ],
        [
          deleteExternalDestination,
          jest.fn().mockResolvedValue(destinationDeleteMutationPopulator()),
        ],
      ]);

      findDestinationUrl().vm.$emit('input', 'https://example.test');
      await setHeadersRowData(0, { name: 'row header', value: 'row value' });
      await setHeadersRowData(1, { name: 'row header 1', value: 'row value 1' });
      findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
      await waitForPromises();

      expect(findAlertErrors()).toHaveLength(1);
      expect(findAlertErrors().at(0).text()).toBe(errorMsg);
      expect(wrapper.emitted('added')).not.toBeDefined();
    });

    it('should not emit add destination event and reports error when network error occurs while adding headers', async () => {
      const sentryError = new Error('Network error');
      const sentryCaptureExceptionSpy = jest.spyOn(Sentry, 'captureException');
      createComponent(mountExtended, { showStreamsHeaders: true }, [
        [
          externalAuditEventDestinationCreate,
          jest.fn().mockResolvedValue(destinationCreateMutationPopulator()),
        ],
        [
          externalAuditEventDestinationHeaderCreate,
          jest
            .fn()
            .mockResolvedValueOnce(destinationHeaderCreateMutationPopulator())
            .mockRejectedValue(sentryError),
        ],
        [
          deleteExternalDestination,
          jest.fn().mockResolvedValue(destinationDeleteMutationPopulator()),
        ],
      ]);

      findDestinationUrl().vm.$emit('input', 'https://example.test');
      await setHeadersRowData(0, { name: 'row header', value: 'row value' });
      await setHeadersRowData(1, { name: 'row header 1', value: 'row value 1' });
      findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
      await waitForPromises();

      expect(findAlertErrors()).toHaveLength(1);
      expect(findAlertErrors().at(0).text()).toBe(AUDIT_STREAMS_NETWORK_ERRORS.CREATING_ERROR);
      expect(sentryCaptureExceptionSpy).toHaveBeenCalledWith(sentryError);
      expect(wrapper.emitted('added')).not.toBeDefined();
    });
  });

  describe('cancel event', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should emit cancel event correctly', () => {
      findCancelBtn().vm.$emit('click');

      expect(wrapper.emitted('cancel')).toBeDefined();
    });
  });

  describe('HTTP headers table', () => {
    beforeEach(() => {
      createComponent(mountExtended, { showStreamsHeaders: true });
    });

    it.each`
      name     | value    | rowCount
      ${'abc'} | ${''}    | ${1}
      ${''}    | ${'abc'} | ${1}
      ${'abc'} | ${'abc'} | ${2}
    `(
      'should add a new blank row only when both the name and value are filled',
      async ({ name, value, rowCount }) => {
        await setHeadersRowData(0, { name, value });

        expect(findHeadersRows()).toHaveLength(rowCount);
      },
    );

    it.each`
      name     | value    | disabled
      ${'abc'} | ${''}    | ${true}
      ${''}    | ${'abc'} | ${true}
      ${'abc'} | ${'abc'} | ${false}
    `(
      'should enable the add button only when both the name and value are filled',
      async ({ name, value, disabled }) => {
        await findDestinationUrl().setValue('https://example.test');
        await setHeadersRowData(0, { name, value });

        expect(findAddBtn().props('disabled')).toBe(disabled);
      },
    );

    it('should not add a new blank row if the header value is a duplicate', async () => {
      await findDestinationUrl().setValue('https://example.test');
      await setHeadersRowData(0, { name: 'row header', value: 'row value' });

      expect(findHeadersRows()).toHaveLength(2);

      await setHeadersRowData(1, { name: 'row header', value: 'row value' });

      expect(findHeadersRows()).toHaveLength(2);
      expect(findHeaderNameInput(1).classes()).toContain('is-invalid');
      expect(findHeadersCell(1, 0).text()).toContain(
        ADD_STREAM_EDITOR_I18N.HEADER_INPUT_DUPLICATE_ERROR,
      );
      expect(findAddBtn().props('disabled')).toBe(true);
    });

    it('should add a new blank row once a duplicate value is changed', async () => {
      await findDestinationUrl().setValue('https://example.test');
      await setHeadersRowData(0, { name: 'row header', value: 'row value' });
      await setHeadersRowData(1, { name: 'row header', value: 'row value' });

      expect(findHeadersRows()).toHaveLength(2);
      expect(findHeaderNameInput(1).classes()).toContain('is-invalid');
      expect(findAddBtn().props('disabled')).toBe(true);

      await setHeadersRowData(1, { name: 'row header 2', value: 'row value' });

      expect(findHeaderNameInput(1).classes()).toContain('is-valid');
      expect(findAddBtn().props('disabled')).toBe(false);
      expect(findHeadersRows()).toHaveLength(3);
    });

    it('should delete a row when the delete button is clicked', async () => {
      await setHeadersRowData(0, { name: 'row header', value: 'row value' });
      await setHeadersRowData(1, { name: 'row header 2', value: 'row value 2' });

      expect(findHeadersRows()).toHaveLength(3);

      await findHeaderDeleteBtn(1).trigger('click');

      expect(findHeadersRows()).toHaveLength(2);
      expect(findHeaderNameInput(0).element.value).toBe('row header');
      expect(findHeaderValueInput(0).element.value).toBe('row value');
      expect(findHeaderNameInput(1).element.value).toBe('');
      expect(findHeaderValueInput(1).element.value).toBe('');
    });

    it('should add a blank row if the last row was deleted', async () => {
      await setHeadersRowData(0, { name: 'row header', value: '' });

      expect(findHeadersRows()).toHaveLength(1);

      await findHeaderDeleteBtn(0).trigger('click');

      expect(findHeadersRows()).toHaveLength(1);
      expect(findHeaderNameInput(0).element.value).toBe('');
      expect(findHeaderValueInput(0).element.value).toBe('');
    });

    it('should show the maximum number of rows message when the maximum is reached', async () => {
      for (let i = 0; i < maxHeaders; i += 1) {
        // This should be done synchronously because each new input will trigger a new one up to the maximum
        // eslint-disable-next-line no-await-in-loop
        await setHeadersRowData(i, { name: `row header ${i}`, value: `row value ${i}` });
      }

      expect(findHeadersRows()).toHaveLength(maxHeaders);
      expect(findMaximumHeadersText()).toMatchInterpolatedText(
        sprintf(ADD_STREAM_EDITOR_I18N.MAXIMUM_HEADERS_TEXT, { number: maxHeaders }),
      );
    });
  });
});
