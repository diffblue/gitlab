import { GlButton, GlFormSelect } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import SelectionSummary from 'ee/security_dashboard/components/pipeline/selection_summary_vuex.vue';

Vue.use(Vuex);

jest.mock('~/vue_shared/plugins/global_toast');

describe('Selection Summary', () => {
  let store;
  let wrapper;
  const dismissSelectedVulnerabilitiesMock = jest.fn();

  const setSelectedVulnerabilitiesCount = (count) => {
    store.state.vulnerabilities.count = count;
  };

  const createComponent = () => {
    store = new Vuex.Store({
      modules: {
        vulnerabilities: {
          namespaced: true,
          state: {
            count: 0,
          },
          getters: {
            selectedVulnerabilitiesCount: () => store.state.vulnerabilities.count,
          },
          actions: {
            dismissSelectedVulnerabilities: dismissSelectedVulnerabilitiesMock,
          },
        },
      },
    });
    wrapper = mount(SelectionSummary, { store });
  };

  beforeEach(() => {
    createComponent();
  });

  const formSelect = () => wrapper.findComponent(GlFormSelect);
  const dismissMessage = () => wrapper.find('[data-testid="dismiss-message"]');
  const dismissButton = () => wrapper.findComponent(GlButton);

  it('renders the form', () => {
    expect(formSelect().exists()).toBe(true);
  });

  describe('dismiss message', () => {
    it('renders when no vulnerabilities selected', () => {
      expect(dismissMessage().text()).toBe('Dismiss 0 selected vulnerabilities as');
    });

    it('renders when 1 vulnerability selected', async () => {
      setSelectedVulnerabilitiesCount(1);
      await nextTick();

      expect(dismissMessage().text()).toBe('Dismiss 1 selected vulnerability as');
    });

    it('renders when 2 vulnerabilities selected', async () => {
      setSelectedVulnerabilitiesCount(2);
      await nextTick();

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

      setSelectedVulnerabilitiesCount(1);

      const option = formSelect().findAll('option').at(1);
      option.setSelected();
      formSelect().trigger('change');

      await nextTick();

      expect(wrapper.vm.dismissalReason).toEqual(option.attributes('value'));
      expect(dismissButton().props().disabled).toBe(false);
    });

    it('should call the dismissSelectedVulnerabilities action with the expected data', async () => {
      setSelectedVulnerabilitiesCount(2);
      const option = formSelect().findAll('option').at(1);
      option.setSelected();
      formSelect().trigger('change');
      await nextTick();

      dismissButton().trigger('submit');
      await nextTick();

      expect(dismissSelectedVulnerabilitiesMock).toHaveBeenCalledTimes(1);
      expect(dismissSelectedVulnerabilitiesMock).toHaveBeenCalledWith(expect.anything(), {
        comment: option.attributes('value'),
      });
    });
  });
});
