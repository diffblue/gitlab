import { shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import StatusPageSettingsForm from 'ee/status_page_settings/components/settings_form.vue';
import createStore from 'ee/status_page_settings/store';

describe('Status Page settings form', () => {
  let wrapper;
  const { state } = createStore();
  const updateStatusPageSettingsSpy = jest.fn();

  const fakeStore = () => {
    return new Vuex.Store({
      state,
      actions: {
        updateStatusPageSettings: updateStatusPageSettingsSpy,
      },
    });
  };

  const findForm = () => wrapper.findComponent({ ref: 'settingsForm' });
  const findToggleButton = () => wrapper.findComponent({ ref: 'toggleBtn' });
  const findSectionHeader = () => wrapper.findComponent({ ref: 'sectionHeader' });
  const findSectionSubHeader = () => wrapper.findComponent({ ref: 'sectionSubHeader' });

  beforeEach(() => {
    wrapper = shallowMount(StatusPageSettingsForm, { store: fakeStore() });
  });

  describe('default state', () => {
    it('should match the default snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  it('renders header text', () => {
    expect(findSectionHeader().text()).toBe('Status page');
  });

  describe('expand/collapse button', () => {
    it('renders as an expand button by default', () => {
      expect(findToggleButton().text()).toBe('Expand');
    });
  });

  describe('sub-header', () => {
    it('renders descriptive text', () => {
      expect(findSectionSubHeader().text()).toContain(
        'Configure file storage settings to link issues in this project to an external status page.',
      );
    });
  });

  describe('form', () => {
    describe('submit button', () => {
      it('submits form on click', () => {
        findForm().trigger('submit');
        expect(updateStatusPageSettingsSpy).toHaveBeenCalled();
      });
    });
  });
});
