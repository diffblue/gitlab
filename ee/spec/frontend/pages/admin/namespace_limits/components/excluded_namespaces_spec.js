import { shallowMount, mount } from '@vue/test-utils';
import { GlAlert, GlTable, GlButton, GlModal } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import ExcludedNamespacesForm from 'ee/pages/admin/namespace_limits/components/excluded_namespaces_form.vue';
import {
  LIST_EXCLUSIONS_ENDPOINT,
  DELETE_EXCLUSION_ENDPOINT,
  exclusionListFetchError,
} from 'ee/pages/admin/namespace_limits/constants';
import ExcludedNamespaces from 'ee/pages/admin/namespace_limits/components/excluded_namespaces.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_BAD_REQUEST } from '~/lib/utils/http_status';
import { mockData } from '../mock_data';

describe('ExcludedNamespaces', () => {
  let wrapper;
  let axiosMock;
  const showMock = jest.fn();
  const listExclusionsEndpoint = LIST_EXCLUSIONS_ENDPOINT.replace(':version', 'v4');
  const deleteExclusionEndpoint = DELETE_EXCLUSION_ENDPOINT.replace(':version', 'v4');

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(ExcludedNamespaces, {
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: { show: showMock },
        }),
      },
    });
  };

  const findForm = () => wrapper.findComponent(ExcludedNamespacesForm);
  const findTable = () => wrapper.findComponent(GlTable);
  const findTableRowCells = (row) => findTable().find('tbody').findAll('tr').at(row).findAll('td');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModal = () => wrapper.findComponent(GlModal);

  beforeEach(() => {
    window.gon = { api_version: 'v4' };
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    showMock.mockClear();
  });

  describe('rendering components', () => {
    beforeEach(async () => {
      axiosMock.onGet(listExclusionsEndpoint).replyOnce(HTTP_STATUS_OK, mockData);
      createComponent();
      await waitForPromises();
    });

    it('renders the excluded namespaces table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('renders excluded namespaces form', () => {
      expect(findForm().exists()).toBe(true);
    });

    it('marks the table as busy when loading is true', async () => {
      expect(findTable().attributes('busy')).toBeUndefined();
      await findForm().vm.$emit('added');
      expect(findTable().attributes('busy')).toBe('true');
    });
  });

  describe('exclusion table', () => {
    it('calls the exclusion list endpoint on component mount', async () => {
      axiosMock.onGet(listExclusionsEndpoint).replyOnce(HTTP_STATUS_OK, mockData);
      createComponent();
      await waitForPromises();
      expect(axiosMock.history.get.length).toBe(1);
    });

    it('renders an error if there is a problem fetching the list', async () => {
      axiosMock.onGet(listExclusionsEndpoint).replyOnce(HTTP_STATUS_BAD_REQUEST);
      createComponent();
      await waitForPromises();
      expect(axiosMock.history.get.length).toBe(1);
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toEqual(exclusionListFetchError);
    });

    it('renders the list of excluded namespaces', async () => {
      axiosMock.onGet(listExclusionsEndpoint).replyOnce(HTTP_STATUS_OK, mockData);
      createComponent({ mountFn: mount });
      await waitForPromises();

      // ensure the table rows are being rendered as expected
      mockData.forEach((item, row) => {
        const cells = findTableRowCells(row);
        expect(cells.at(0).text()).toEqual(item.namespace_name);
        expect(cells.at(1).text()).toEqual(`${item.namespace_id}`);
        expect(cells.at(2).text()).toEqual(item.reason);
        expect(cells.at(3).findComponent(GlButton).text()).toBe('Delete');
      });
    });
  });

  describe('deleting exclusion', () => {
    beforeEach(async () => {
      axiosMock.onGet(listExclusionsEndpoint).replyOnce(HTTP_STATUS_OK, [mockData[0]]);
      axiosMock.onDelete(deleteExclusionEndpoint).replyOnce(HTTP_STATUS_OK);

      createComponent({ mountFn: mount });
      await waitForPromises();
      wrapper.findComponent(GlTable).findComponent(GlButton).trigger('click');
    });

    it('opens confirmation modal when delete button is clicked', () => {
      expect(showMock).toHaveBeenCalled();
      expect(findModal().props()).toMatchObject({
        title: 'Deletion confirmation',
        actionPrimary: { text: 'Confirm deletion' },
      });
    });

    it('sends deletion request to the backend when deletion modal is confirmed', async () => {
      findModal().vm.$emit('primary');
      await waitForPromises();
      expect(axiosMock.history.delete.length).toBe(1);
    });
  });
});
