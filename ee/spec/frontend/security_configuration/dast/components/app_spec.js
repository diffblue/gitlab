import { shallowMount } from '@vue/test-utils';
import App from 'ee/security_configuration/dast/components/app.vue';
import DastConfigurationHeader from 'ee/security_configuration/dast/components/dast_configuration_header.vue';
import DastConfigurationForm from 'ee/security_configuration/dast/components/configuration_form.vue';

describe('EE - DAST Configuration App', () => {
  let wrapper;
  const projectPath = 'projectPath';
  const dastEnabled = true;
  const pipelineCreatedAt = '2022-06-09 13:50:04 UTC';
  const pipelineId = '11';
  const pipelinePath = 'pipelinePath';

  const createComponent = () => {
    wrapper = shallowMount(App, {
      provide: {
        projectPath,
        dastEnabled,
        pipelinePath,
        pipelineCreatedAt,
        pipelineId,
      },
    });
  };

  const findForm = () => wrapper.findComponent(DastConfigurationForm);
  const findHeader = () => wrapper.findComponent(DastConfigurationHeader);

  beforeEach(() => {
    createComponent();
  });

  it('mounts', () => {
    expect(wrapper.exists()).toBe(true);
  });

  it('loads the scan configuration form by default', () => {
    expect(findForm().exists()).toBe(true);
  });

  it('should render dast configuration header', () => {
    expect(findHeader().props()).toMatchObject({
      dastEnabled,
      pipelinePath,
      pipelineCreatedAt,
      pipelineId,
    });
  });
});
