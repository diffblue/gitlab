import MockAdapter from 'axios-mock-adapter';
import { GlFormInput, GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ExcludedNamespacesForm, {
  limitExclusionEndpoint,
} from 'ee/pages/admin/namespace_limits/components/excluded_namespaces_form.vue';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_IM_A_TEAPOT,
} from '~/lib/utils/http_status';
import EntitySelect from '~/vue_shared/components/entity_select/entity_select.vue';

describe('ExcludedNamespacesForm', () => {
  let wrapper;
  const $toast = {
    show: jest.fn(),
  };

  const mockNamespaceId = 1;
  const mockReason = 'Some reason for excluding the namespace';

  const createComponent = () => {
    wrapper = shallowMountExtended(ExcludedNamespacesForm, {
      stubs: { EntitySelect },
      mocks: {
        $toast,
      },
    });
  };

  const findEntitySelect = () => wrapper.findComponent(EntitySelect);
  const findReasonInput = () => wrapper.findComponent(GlFormInput);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const submitForm = () => wrapper.find('form').trigger('submit');
  const fillAndSubmitForm = () => {
    findReasonInput().vm.$emit('input', mockReason);
    findEntitySelect().vm.$emit('input', { value: mockNamespaceId });

    submitForm();

    return waitForPromises();
  };

  describe('rendering components', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders entity_select component', () => {
      expect(findEntitySelect().exists()).toBe(true);
      expect(findEntitySelect().props()).toEqual(
        expect.objectContaining({
          label: 'Exclude namespace',
          headerText: 'Select a group',
        }),
      );
    });

    it('renders excluding reason form input', () => {
      expect(findReasonInput().exists()).toBe(true);
      expect(findReasonInput().attributes('placeholder')).toBe(
        'Reason for excluding this namespace',
      );
    });
  });

  describe('submitting exclusion', () => {
    let axiosMock;

    const expectedUrl = limitExclusionEndpoint
      .replace(':version', 'v4')
      .replace(':id', mockNamespaceId);

    beforeEach(() => {
      createComponent();
      window.gon = { api_version: 'v4' };
      jest.spyOn(axios, 'post');
      axiosMock = new MockAdapter(axios);
    });

    afterEach(() => {
      axiosMock.restore();
    });

    describe('submitting empty inputs', () => {
      it('shows alert with error message', async () => {
        await submitForm();
        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(
          'You must select a namespace and add a reason for excluding it',
        );
      });
    });

    describe('successfully submitting data', () => {
      beforeEach(() => {
        const expectedResponse = {
          id: 5,
          namespace_id: mockNamespaceId,
          namespace_name: 'MockNamespace',
          reason: mockReason,
        };

        axiosMock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK, expectedResponse);

        return fillAndSubmitForm();
      });

      it('sends the data to API endpoint', () => {
        expect(axios.post).toHaveBeenCalledWith(expectedUrl, { reason: mockReason });
      });

      it('emits `added` event', () => {
        expect(wrapper.emitted('added')).toEqual([[]]);
      });

      it('shows a toast that exclusion was successfully added', () => {
        expect($toast.show).toHaveBeenCalledWith('Exclusion added successfully');
      });
    });

    describe('backend errors', () => {
      describe('when backend error is available', () => {
        const mockBackendErrorMessage = 'There is something wrong with the exclusion request';

        beforeEach(() => {
          axiosMock.onPost(expectedUrl).replyOnce(HTTP_STATUS_NOT_FOUND, {
            message: mockBackendErrorMessage,
          });
          return fillAndSubmitForm();
        });

        it('renders the backend error', () => {
          expect(findAlert().text()).toBe(mockBackendErrorMessage);
        });
      });

      describe('when backend error is not available', () => {
        beforeEach(() => {
          axiosMock.onPost(expectedUrl).replyOnce(HTTP_STATUS_IM_A_TEAPOT);
          return fillAndSubmitForm();
        });

        it('renders a response error as-is', () => {
          expect(findAlert().text()).toBe('Error: Request failed with status code 418');
        });
      });
    });
  });
});
