import { GlButton, GlFormSelect } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import SelectionSummary from 'ee/security_dashboard/components/pipeline/selection_summary_vuex.vue';
import { setupStore } from 'ee/security_dashboard/store/index';
import {
  SELECT_VULNERABILITY,
  RECEIVE_VULNERABILITIES_SUCCESS,
} from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import mockDataVulnerabilities from '../../store/modules/vulnerabilities/data/mock_data_vulnerabilities';

Vue.use(Vuex);

jest.mock('~/vue_shared/plugins/global_toast');

describe('Selection Summary', () => {
  let store;
  let wrapper;
  let mock;

  const createComponent = () => {
    store = new Vuex.Store();
    setupStore(store);
    wrapper = mount(SelectionSummary, {
      store,
    });

    store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_SUCCESS}`, {
      vulnerabilities: mockDataVulnerabilities,
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mock.restore();
  });

  const formSelect = () => wrapper.findComponent(GlFormSelect);
  const dismissMessage = () => wrapper.find('[data-testid="dismiss-message"]');
  const dismissButton = () => wrapper.findComponent(GlButton);

  const selectByIndex = (index) =>
    store.commit(`vulnerabilities/${SELECT_VULNERABILITY}`, mockDataVulnerabilities[index].id);

  it('renders the form', () => {
    expect(formSelect().exists()).toBe(true);
  });

  describe('dismiss message', () => {
    it('renders when no vulnerabilities selected', () => {
      expect(dismissMessage().text()).toBe('Dismiss 0 selected vulnerabilities as');
    });
    it('renders when 1 vulnerability selected', async () => {
      selectByIndex(0);

      await waitForPromises();

      expect(dismissMessage().text()).toBe('Dismiss 1 selected vulnerability as');
    });
    it('renders when 2 vulnerabilities selected', async () => {
      selectByIndex(0);
      selectByIndex(1);

      await waitForPromises();

      expect(dismissMessage().text()).toBe('Dismiss 2 selected vulnerabilities as');
    });
  });

  describe('dismiss button', () => {
    it('should be disabled if an option is not selected', () => {
      expect(dismissButton().exists()).toBe(true);
      expect(dismissButton().props().disabled).toBe(true);
    });

    it('should be enabled if a vulnerability is selected and dismissal reason is selected', async () => {
      expect(wrapper.vm.dismissalReason).toBe(null);
      expect(wrapper.findAll('option')).toHaveLength(4);

      selectByIndex(0);

      const option = formSelect().findAll('option').at(1);
      option.setSelected();
      formSelect().trigger('change');

      await nextTick();

      expect(wrapper.vm.dismissalReason).toEqual(option.attributes('value'));
      expect(dismissButton().props().disabled).toBe(false);
    });

    it('should make an API request for each vulnerability', async () => {
      mock.onPost().reply(HTTP_STATUS_OK);

      selectByIndex(0);
      selectByIndex(1);

      const option = formSelect().findAll('option').at(1);
      option.setSelected();
      formSelect().trigger('change');

      await waitForPromises();

      dismissButton().trigger('submit');

      await axios.waitForAll();

      expect(mock.history.post.length).toBe(2);
      expect(mock.history.post[0].data).toContain(option.attributes('value'));
    });
  });
});
