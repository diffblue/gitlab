import { GlBadge, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DastConfigurationHeader from 'ee/security_configuration/dast/components/dast_configuration_header.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

describe('EE DAST Configuration Header', () => {
  let wrapper;

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

  it('should be disabled by default', () => {
    const badgeLabel = s__('DastConfig|Not enabled');
    const badgeText = s__('DastConfig|No previous scans found for this project');

    createComponent();

    expect(findBadge().props('variant')).toBe('neutral');
    expect(findBadge().text()).toContain(badgeLabel);
    expect(wrapper.text()).toContain(badgeText);
    expect(findLink().exists()).toBe(false);
  });

  it('should be enabled if dast is enabled', () => {
    const dastEnabled = true;
    const pipelineId = 'pipeline-id';
    const pipelinePath = 'pipeline-path';
    const pipelineCreatedAt = '2022-06-20T10:17:18Z';
    const badgeLabel = s__('DastConfig|Enabled');

    createComponent({
      dastEnabled,
      pipelineId,
      pipelinePath,
      pipelineCreatedAt,
    });

    expect(findBadge().props('variant')).toBe('success');
    expect(findBadge().text()).toContain(badgeLabel);
    expect(findHeaderText().text()).toContain(
      timeagoMixin.methods.timeFormatted(pipelineCreatedAt),
    );

    expect(findLink().exists()).toBe(true);
    expect(findLink().attributes('href')).toEqual(pipelinePath);
  });
});
