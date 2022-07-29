import { GlBadge, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DastConfigurationHeader from 'ee/security_configuration/dast/components/dast_configuration_header.vue';

describe('EE DAST Configuration Header', () => {
  let wrapper;
  const pipelineId = 'pipeline-id';
  const pipelinePath = 'pipeline-path';
  const pipelineCreatedAt = '2022-06-20T10:17:18Z';

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(DastConfigurationHeader, {
      propsData: {
        ...options,
      },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findLink = () => wrapper.findComponent(GlLink);
  const findHeaderText = () => wrapper.findByTestId('dast-header-text');

  it('renders header elements disabled', () => {
    const badgeLabel = s__('DastConfig|Not enabled');
    const badgeText = s__('DastConfig|No previous scans found for this project');

    createComponent();

    expect(findBadge().props('variant')).toBe('neutral');
    expect(findBadge().text()).toBe(badgeLabel);
    expect(findHeaderText().text()).toBe(badgeText);
    expect(findLink().exists()).toBe(false);
  });

  it('should show latest pipeline info if dast is disabled but used before', () => {
    const badgeLabel = s__('DastConfig|Not enabled');
    const badgeText = s__('DastConfig|Last scan triggered');

    createComponent({
      dastEnabled: false,
      pipelineId,
      pipelinePath,
      pipelineCreatedAt,
    });

    expect(findBadge().props('variant')).toBe('neutral');
    expect(findBadge().text()).toBe(badgeLabel);
    expect(findHeaderText().text()).toBe(`${badgeText} in 1 year in pipeline`);
  });

  it('should be enabled if dast is enabled', () => {
    const dastEnabled = true;
    const badgeLabel = s__('DastConfig|Enabled');

    createComponent({
      dastEnabled,
      pipelineId,
      pipelinePath,
      pipelineCreatedAt,
    });

    expect(findBadge().props('variant')).toBe('success');
    expect(findBadge().text()).toBe(badgeLabel);
    expect(findHeaderText().text()).toBe('Last scan triggered in 1 year in pipeline');

    expect(findLink().exists()).toBe(true);
    expect(findLink().attributes('href')).toBe(pipelinePath);
  });
});
