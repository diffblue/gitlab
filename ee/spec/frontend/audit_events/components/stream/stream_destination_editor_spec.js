import Vue from 'vue';
import VueApollo from 'vue-apollo';
import {
  GlAccordion,
  GlAccordionItem,
  GlButton,
  GlFormCheckbox,
  GlForm,
  GlTableLite,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { sprintf } from '~/locale';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  shallowMountExtended,
  mountExtended,
  extendedWrapper,
} from 'helpers/vue_test_utils_helper';
import externalAuditEventDestinationCreate from 'ee/audit_events/graphql/mutations/create_external_destination.mutation.graphql';
import externalAuditEventDestinationHeaderCreate from 'ee/audit_events/graphql/mutations/create_external_destination_header.mutation.graphql';
import externalAuditEventDestinationHeaderUpdate from 'ee/audit_events/graphql/mutations/update_external_destination_header.mutation.graphql';
import externalAuditEventDestinationHeaderDelete from 'ee/audit_events/graphql/mutations/delete_external_destination_header.mutation.graphql';
import deleteExternalDestination from 'ee/audit_events/graphql/mutations/delete_external_destination.mutation.graphql';
import deleteExternalDestinationFilters from 'ee/audit_events/graphql/mutations/delete_external_destination_filters.mutation.graphql';
import updateExternalDestinationFilters from 'ee/audit_events/graphql/mutations/update_external_destination_filters.mutation.graphql';
import StreamDestinationEditor from 'ee/audit_events/components/stream/stream_destination_editor.vue';
import StreamFilters from 'ee/audit_events/components/stream/stream_filters.vue';
import { AUDIT_STREAMS_NETWORK_ERRORS, ADD_STREAM_EDITOR_I18N } from 'ee/audit_events/constants';
import {
  destinationCreateMutationPopulator,
  destinationDeleteMutationPopulator,
  destinationHeaderCreateMutationPopulator,
  destinationHeaderUpdateMutationPopulator,
  destinationHeaderDeleteMutationPopulator,
  groupPath,
  mockExternalDestinations,
  mockExternalDestinationHeader,
  destinationFilterRemoveMutationPopulator,
  destinationFilterUpdateMutationPopulator,
  mockFiltersOptions,
  mockRemoveFilterSelect,
  mockRemoveFilterRemaining,
  mockAddFilterSelect,
  mockAddFilterRemaining,
} from '../../mock_data';

Vue.use(VueApollo);

describe('StreamDestinationEditor', () => {
  let wrapper;

  const maxHeaders = 3;

  const createComponent = (
    mountFn = shallowMountExtended,
    props = {},
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
        maxHeaders,
      },
      propsData: {
        groupEventFilters: mockFiltersOptions,
        ...props,
      },
      apolloProvider: mockApollo,
    });
  };

  const findWarningMessage = () => wrapper.findByTestId('data-warning');
  const findAlertErrors = () => wrapper.findAllByTestId('alert-errors');
  const findDestinationForm = () => wrapper.findComponent(GlForm);
  const findHeadersTable = () => wrapper.findComponent(GlTableLite);
  const findMaximumHeadersText = () => wrapper.findByTestId('maximum-headers').text();
  const findAddHeaderBtn = () => wrapper.findByTestId('add-header-row-button');
  const findAddStreamBtn = () => wrapper.findByTestId('stream-destination-add-button');
  const findCancelStreamBtn = () => wrapper.findByTestId('stream-destination-cancel-button');

  const findDestinationUrlFormGroup = () => wrapper.findByTestId('destination-url-form-group');
  const findDestinationUrl = () => wrapper.findByTestId('destination-url');

  const findFilteringHeader = () => wrapper.findByTestId('filtering-header');
  const findFilteringSubheader = () => wrapper.findByTestId('filtering-subheader');
  const findAccordion = () => wrapper.findComponent(GlAccordion);
  const findAllAccordionItems = () => wrapper.findAllComponents(GlAccordionItem);
  const findFilters = () => wrapper.findComponent(StreamFilters);

  const findHeadersRows = () => findHeadersTable().find('tbody').findAll('tr');
  const findHeadersHeaderCell = (tdIdx) =>
    findHeadersTable().find('thead tr').findAll('th').at(tdIdx);
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
        expect(findDestinationUrl().props('disabled')).toBe(undefined);
        expect(findDestinationUrl().attributes('placeholder')).toBe(
          ADD_STREAM_EDITOR_I18N.DESTINATION_URL_PLACEHOLDER,
        );
      });
    });

    describe('HTTP headers', () => {
      beforeEach(() => {
        createComponent(mountExtended);
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
        expect(findHeaderCheckbox(0).find('input').attributes('disabled')).toBeDefined();
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
      expect(wrapper.emitted('error')).toBeUndefined();
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
      expect(wrapper.emitted('error')).toBeDefined();
      expect(wrapper.emitted('added')).toBeUndefined();
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
      expect(wrapper.emitted('error')).toBeDefined();
      expect(wrapper.emitted('added')).toBeUndefined();
    });
  });

  describe('add destination event with headers', () => {
    it('should emit add event after destination and headers are added', async () => {
      createComponent(mountExtended, {}, [
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
      await findAddHeaderBtn().trigger('click');
      await setHeadersRowData(1, { name: 'row header 1', value: 'row value 1' });
      findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
      await waitForPromises();

      expect(findAlertErrors()).toHaveLength(0);
      expect(wrapper.emitted('error')).toBeUndefined();
      expect(wrapper.emitted('added')).toBeDefined();
    });

    it('should ignore empty headers and emit add event after destination and headers are added', async () => {
      const headerCreateSpy = jest
        .fn()
        .mockResolvedValue(destinationHeaderCreateMutationPopulator());

      createComponent(mountExtended, {}, [
        [
          externalAuditEventDestinationCreate,
          jest.fn().mockResolvedValue(destinationCreateMutationPopulator()),
        ],
        [externalAuditEventDestinationHeaderCreate, headerCreateSpy],
      ]);

      findDestinationUrl().vm.$emit('input', 'https://example.test');
      await setHeadersRowData(0, { name: 'row header', value: 'row value' });
      await findAddHeaderBtn().trigger('click');
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
      expect(wrapper.emitted('error')).toBeUndefined();
      expect(wrapper.emitted('added')).toBeDefined();
    });

    it('should not emit add destination event and reports error when server returns error while adding headers', async () => {
      const errorMsg = 'Destination hosts limit exceeded';
      createComponent(mountExtended, {}, [
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
      await findAddHeaderBtn().trigger('click');
      await setHeadersRowData(1, { name: 'row header 1', value: 'row value 1' });
      findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
      await waitForPromises();

      expect(findAlertErrors()).toHaveLength(1);
      expect(findAlertErrors().at(0).text()).toBe(errorMsg);
      expect(wrapper.emitted('error')).toBeDefined();
      expect(wrapper.emitted('added')).toBeUndefined();
    });

    it('should not emit add destination event and reports error when network error occurs while adding headers', async () => {
      const sentryError = new Error('Network error');
      const sentryCaptureExceptionSpy = jest.spyOn(Sentry, 'captureException');
      createComponent(mountExtended, {}, [
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
      await findAddHeaderBtn().trigger('click');
      await setHeadersRowData(1, { name: 'row header 1', value: 'row value 1' });
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

  describe('HTTP headers table', () => {
    beforeEach(() => {
      createComponent(mountExtended);
    });

    it('should add a new blank row if the add row button is clicked', async () => {
      await findAddHeaderBtn().trigger('click');

      expect(findHeadersRows()).toHaveLength(2);
    });

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

        expect(findAddStreamBtn().props('disabled')).toBe(disabled);
      },
    );

    it('should delete a row when the delete button is clicked', async () => {
      await setHeadersRowData(0, { name: 'row header', value: 'row value' });
      await findAddHeaderBtn().trigger('click');
      await setHeadersRowData(1, { name: 'row header 2', value: 'row value 2' });
      await findAddHeaderBtn().trigger('click');

      expect(findHeadersRows()).toHaveLength(3);

      await findHeaderDeleteBtn(1).trigger('click');

      expect(findHeadersRows()).toHaveLength(2);
      expect(findHeaderNameInput(0).element.value).toBe('row header');
      expect(findHeaderValueInput(0).element.value).toBe('row value');
      expect(findHeaderNameInput(1).element.value).toBe('');
      expect(findHeaderValueInput(1).element.value).toBe('');
    });

    it('should add a blank row if the only row is deleted', async () => {
      await setHeadersRowData(0, { name: 'row header', value: '' });

      expect(findHeadersRows()).toHaveLength(1);

      await findHeaderDeleteBtn(0).trigger('click');

      expect(findHeadersRows()).toHaveLength(1);
      expect(findHeaderNameInput(0).element.value).toBe('');
      expect(findHeaderValueInput(0).element.value).toBe('');
    });

    it('should show the maximum number of rows message when the maximum is reached', async () => {
      // Max headers === 3 and one row already exists
      await findAddHeaderBtn().trigger('click');
      await findAddHeaderBtn().trigger('click');

      expect(findHeadersRows()).toHaveLength(maxHeaders);
      expect(findAddHeaderBtn().exists()).toBe(false);
      expect(findMaximumHeadersText()).toMatchInterpolatedText(
        sprintf(ADD_STREAM_EDITOR_I18N.MAXIMUM_HEADERS_TEXT, { number: maxHeaders }),
      );
    });
  });

  describe('when editing an existing destination', () => {
    const item = {
      ...mockExternalDestinations[0],
      headers: { nodes: [mockExternalDestinationHeader(), mockExternalDestinationHeader()] },
    };

    describe('renders', () => {
      beforeEach(() => {
        createComponent(mountExtended, { item });
      });

      it('should not render the destinations warning', () => {
        expect(findWarningMessage().exists()).toBe(false);
      });

      it('disables the destination URL field', () => {
        expect(findDestinationUrl().element.value).toBe(mockExternalDestinations[0].destinationUrl);
        expect(findDestinationUrl().attributes('disabled')).toBeDefined();
      });

      it('changes the save button text', () => {
        expect(findAddStreamBtn().attributes('name')).toBe(ADD_STREAM_EDITOR_I18N.SAVE_BUTTON_NAME);
        expect(findAddStreamBtn().text()).toBe(ADD_STREAM_EDITOR_I18N.SAVE_BUTTON_TEXT);
      });
    });

    describe('update destinations headers', () => {
      const updatedHeader = { ...item.headers.nodes[0], newValue: 'CHANGED_VALUE' };
      const deletedHeader = item.headers.nodes[1];
      const addedHeader = mockExternalDestinationHeader();

      const setupUpdatedHeaders = async (updated, added) => {
        findDestinationUrl().vm.$emit('input', 'https://example.test');
        await setHeadersRowData(0, { name: updated.key, value: updated.newValue });
        await findHeaderDeleteBtn(1).trigger('click');
        await setHeadersRowData(1, { name: added.key, value: added.value });
        findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });

        return waitForPromises();
      };

      it('emits the updated event when the headers are added, updated, and deleted', async () => {
        const headerCreateSpy = jest
          .fn()
          .mockResolvedValue(destinationHeaderCreateMutationPopulator());
        const headerUpdateSpy = jest
          .fn()
          .mockResolvedValue(destinationHeaderUpdateMutationPopulator());
        const headerDeleteSpy = jest
          .fn()
          .mockResolvedValue(destinationHeaderDeleteMutationPopulator());

        createComponent(mountExtended, { item }, [
          [externalAuditEventDestinationHeaderCreate, headerCreateSpy],
          [externalAuditEventDestinationHeaderUpdate, headerUpdateSpy],
          [externalAuditEventDestinationHeaderDelete, headerDeleteSpy],
        ]);

        await setupUpdatedHeaders(updatedHeader, addedHeader);

        expect(headerDeleteSpy).toHaveBeenCalledTimes(1);
        expect(headerDeleteSpy).toHaveBeenCalledWith({ headerId: deletedHeader.id });
        expect(headerUpdateSpy).toHaveBeenCalledTimes(1);
        expect(headerUpdateSpy).toHaveBeenCalledWith({
          headerId: updatedHeader.id,
          key: updatedHeader.key,
          value: updatedHeader.newValue,
        });
        expect(headerCreateSpy).toHaveBeenCalledTimes(1);
        expect(headerCreateSpy).toHaveBeenCalledWith({
          destinationId: item.id,
          key: addedHeader.key,
          value: addedHeader.value,
        });
        expect(findAlertErrors()).toHaveLength(0);
        expect(wrapper.emitted('error')).toBeUndefined();
        expect(wrapper.emitted('updated')).toBeDefined();
      });

      it('should not emit updated event and reports error when server returns error while saving', async () => {
        const errorMsg = 'Destination hosts limit exceeded';

        createComponent(mountExtended, { item }, [
          [
            externalAuditEventDestinationHeaderCreate,
            jest.fn().mockResolvedValue(destinationHeaderCreateMutationPopulator([errorMsg])),
          ],
          [
            externalAuditEventDestinationHeaderUpdate,
            jest.fn().mockResolvedValue(destinationHeaderUpdateMutationPopulator()),
          ],
          [
            externalAuditEventDestinationHeaderDelete,
            jest.fn().mockResolvedValue(destinationHeaderDeleteMutationPopulator()),
          ],
        ]);

        await setupUpdatedHeaders(updatedHeader, addedHeader);

        expect(findAlertErrors()).toHaveLength(1);
        expect(findAlertErrors().at(0).text()).toBe(errorMsg);
        expect(wrapper.emitted('error')).toBeDefined();
        expect(wrapper.emitted('updated')).toBeUndefined();
      });

      it('should not emit updated event and reports error when network error occurs while saving', async () => {
        const sentryError = new Error('Network error');
        const sentryCaptureExceptionSpy = jest.spyOn(Sentry, 'captureException');

        createComponent(mountExtended, { item }, [
          [
            externalAuditEventDestinationHeaderCreate,
            jest.fn().mockResolvedValue(destinationHeaderUpdateMutationPopulator()),
          ],
          [externalAuditEventDestinationHeaderUpdate, jest.fn().mockRejectedValue(sentryError)],
          [
            externalAuditEventDestinationHeaderDelete,
            jest.fn().mockResolvedValue(destinationHeaderDeleteMutationPopulator()),
          ],
        ]);

        await setupUpdatedHeaders(updatedHeader, addedHeader);

        expect(findAlertErrors()).toHaveLength(1);
        expect(findAlertErrors().at(0).text()).toBe(AUDIT_STREAMS_NETWORK_ERRORS.UPDATING_ERROR);
        expect(sentryCaptureExceptionSpy).toHaveBeenCalledWith(sentryError);
        expect(wrapper.emitted('error')).toBeDefined();
        expect(wrapper.emitted('updated')).toBeUndefined();
      });
    });
  });

  describe('destination event filters', () => {
    describe('renders', () => {
      beforeEach(() => {
        createComponent(mountExtended, { item: mockExternalDestinations[1] });
      });

      it('displays the correct text', () => {
        expect(findFilteringHeader().text()).toBe(ADD_STREAM_EDITOR_I18N.HEADER_FILTERING);
        expect(findFilteringSubheader().text()).toBe(ADD_STREAM_EDITOR_I18N.SUBHEADER_FILTERING);
      });

      it('shows an accordion containing a list of event filters', () => {
        expect(findAccordion().exists()).toBe(true);
        expect(findAllAccordionItems()).toHaveLength(1);
        expect(findFilters().props()).toStrictEqual({
          filterOptions: mockFiltersOptions,
          filterSelected: mockExternalDestinations[1].eventTypeFilters,
        });
      });

      it('shows an empty state for a list of event filters when no options are available', () => {
        createComponent(mountExtended, {
          item: mockExternalDestinations[0],
          groupEventFilters: [],
        });

        expect(findAccordion().text()).toContain(
          sprintf(ADD_STREAM_EDITOR_I18N.SUBHEADER_EMPTY_FILTERING, {
            linkStart: '',
            linkEnd: '',
          }),
        );
        expect(findFilters().exists()).toBe(false);
      });
    });

    describe('on change filters', () => {
      it('removes the deselected filters from a destination', async () => {
        const filterRemoveSpy = jest
          .fn()
          .mockResolvedValue(destinationFilterRemoveMutationPopulator());

        createComponent(mountExtended, { item: mockExternalDestinations[1] }, [
          [deleteExternalDestinationFilters, filterRemoveSpy],
        ]);

        findFilters().vm.$emit('updateFilters', mockRemoveFilterSelect);

        findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
        await waitForPromises();

        expect(filterRemoveSpy).toHaveBeenCalledWith({
          destinationId: mockExternalDestinations[1].id,
          eventTypeFilters: mockRemoveFilterRemaining,
        });

        expect(findAlertErrors()).toHaveLength(0);
        expect(wrapper.emitted('error')).toBeUndefined();
        expect(wrapper.emitted('updated')).toBeDefined();
      });

      it('adds the selected filters for a destination', async () => {
        const filterAddSpy = jest
          .fn()
          .mockResolvedValue(destinationFilterUpdateMutationPopulator());

        createComponent(mountExtended, { item: mockExternalDestinations[1] }, [
          [updateExternalDestinationFilters, filterAddSpy],
        ]);

        findFilters().vm.$emit('updateFilters', mockAddFilterSelect);

        findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
        await waitForPromises();

        expect(filterAddSpy).toHaveBeenCalledWith({
          destinationId: mockExternalDestinations[1].id,
          eventTypeFilters: mockAddFilterRemaining,
        });

        expect(findAlertErrors()).toHaveLength(0);
        expect(wrapper.emitted('error')).toBeUndefined();
        expect(wrapper.emitted('updated')).toBeDefined();
      });

      it('should not emit updated event and reports error when network error occurs while saving', async () => {
        const sentryError = new Error('Network error');
        const sentryCaptureExceptionSpy = jest.spyOn(Sentry, 'captureException');
        const filterRemoveSpy = jest.fn().mockRejectedValue(sentryError);

        createComponent(mountExtended, { item: mockExternalDestinations[1] }, [
          [deleteExternalDestinationFilters, filterRemoveSpy],
        ]);

        findFilters().vm.$emit('updateFilters', mockRemoveFilterSelect);

        findDestinationForm().vm.$emit('submit', { preventDefault: () => {} });
        await waitForPromises();

        expect(findAlertErrors()).toHaveLength(1);
        expect(findAlertErrors().at(0).text()).toBe(AUDIT_STREAMS_NETWORK_ERRORS.UPDATING_ERROR);
        expect(sentryCaptureExceptionSpy).toHaveBeenCalledWith(sentryError);
        expect(wrapper.emitted('error')).toBeDefined();
        expect(wrapper.emitted('updated')).toBeUndefined();
      });
    });
  });
});
