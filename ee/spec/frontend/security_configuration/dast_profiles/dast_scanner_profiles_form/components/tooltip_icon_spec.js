import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TooltipIcon from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/components/tooltip_icon.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('Tooltip Icon', () => {
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const title = 'Hello world';

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(TooltipIcon, {
      propsData: {
        title,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders icon correctly', () => {
    expect(findIcon().exists()).toBe(true);
  });

  it('renders tooltip correctly', () => {
    const tooltip = getBinding(findIcon().element, 'gl-tooltip').value;
    expect(tooltip).toBeDefined();
    expect(tooltip).toBe(title);
  });
});
