import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import {
  SEVERITY_CLASS_NAME_MAP,
  SEVERITY_TOOLTIP_TITLE_MAP,
} from 'ee/vue_shared/security_reports/components/constants';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('Severity Badge', () => {
  const SEVERITY_LEVELS = ['critical', 'high', 'medium', 'low', 'info', 'unknown'];

  let wrapper;

  const createWrapper = (propsData = {}) => {
    wrapper = shallowMount(SeverityBadge, {
      propsData: { ...propsData },
      directives: {
        tooltip: createMockDirective('tooltip'),
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findTooltip = () => getBinding(findIcon().element, 'tooltip').value;

  describe.each(SEVERITY_LEVELS)('given a valid severity "%s"', (severity) => {
    beforeEach(() => {
      createWrapper({ severity });
    });

    const className = SEVERITY_CLASS_NAME_MAP[severity];

    it(`renders the component with ${severity} badge`, () => {
      expect(wrapper.find(`.${className}`).exists()).toBe(true);
    });

    it('renders gl-icon with correct name', () => {
      expect(findIcon().props('name')).toBe(`severity-${severity}`);
    });

    it(`renders the component label`, () => {
      const severityFirstLetterUpper = `${severity.charAt(0).toUpperCase()}${severity.slice(1)}`;
      expect(wrapper.text()).toBe(severityFirstLetterUpper);
    });

    it('renders tooltip', () => {
      expect(findTooltip()).toBe(SEVERITY_TOOLTIP_TITLE_MAP[severity]);
    });
  });

  describe.each(['foo', '', ' '])('given an invalid severity "%s"', (invalidSeverity) => {
    beforeEach(() => {
      createWrapper({ severity: invalidSeverity });
    });

    it(`renders an empty component`, () => {
      expect(wrapper.html()).toBe('');
    });
  });
});
