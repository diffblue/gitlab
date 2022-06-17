import { shallowMount } from '@vue/test-utils';
import App from 'ee/security_configuration/dast/components/app.vue';
import DastConfigurationForm from 'ee/security_configuration/dast/components/configuration_form.vue';

describe('EE - DAST Configuration App', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(App);
  };

  const findForm = () => wrapper.findComponent(DastConfigurationForm);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('mounts', () => {
    expect(wrapper.exists()).toBe(true);
  });

  it('loads the scan configuration form by default', () => {
    expect(findForm().exists()).toBe(true);
  });
});
