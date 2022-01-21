import { shallowMount } from '@vue/test-utils';
import StatusPageSettingsForm from 'ee/status_page_settings/components/settings_form.vue';
import createStore from 'ee/status_page_settings/store';

describe('Status Page settings form', () => {
  let wrapper;
  const store = createStore();

  const findForm = () => wrapper.findComponent({ ref: 'settingsForm' });
  const findToggleButton = () => wrapper.findComponent({ ref: 'toggleBtn' });
  const findSectionHeader = () => wrapper.findComponent({ ref: 'sectionHeader' });
  const findSectionSubHeader = () => wrapper.findComponent({ ref: 'sectionSubHeader' });

  beforeEach(() => {
    wrapper = shallowMount(StatusPageSettingsForm, { store });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
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
    beforeEach(() => {
      jest.spyOn(wrapper.vm, 'updateStatusPageSettings').mockImplementation();
    });

    describe('submit button', () => {
      it('submits form on click', () => {
        findForm().trigger('submit');
        expect(wrapper.vm.updateStatusPageSettings).toHaveBeenCalled();
      });
    });
  });
});
