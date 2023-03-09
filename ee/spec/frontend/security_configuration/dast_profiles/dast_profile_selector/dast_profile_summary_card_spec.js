import { GlCard, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { SCANNER_TYPE, SITE_TYPE } from 'ee/on_demand_scans/constants';
import DastProfileSummaryCard from 'ee/security_configuration/dast_profiles/dast_profile_selector/dast_profile_summary_card.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

const propsData = {
  isEditable: true,
  allowSelection: true,
};

describe('DastProfileSummaryCard', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(DastProfileSummaryCard, {
      propsData,
      stubs: { GlCard },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      ...options,
    });
  };

  const findProfileSelectBtn = () => wrapper.findByTestId('profile-select-btn');
  const findProfileEditBtn = () => wrapper.findByTestId('profile-edit-btn');
  const findInUseLabel = () => wrapper.findByTestId('in-use-label');

  beforeEach(() => {
    createComponent();
  });

  it('renders properly', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('emits correctly when a profile is selected', () => {
    findProfileSelectBtn().vm.$emit('click');
    expect(wrapper.emitted('select-profile')).toHaveLength(1);
  });

  describe('when selected profile is in use', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          ...propsData,
          isProfileInUse: true,
          isProfileSelected: true,
        },
      });
    });

    it('shows correct label', () => {
      expect(wrapper.text()).toContain('In use');
      expect(findInUseLabel().findComponent(GlIcon).props('name')).toBe('check-circle-filled');
    });

    it('shows disabled select button', () => {
      expect(findProfileSelectBtn().props('disabled')).toBe(true);
    });

    it('displays the correct tooltip', () => {
      const tooltip = getBinding(findInUseLabel().element, 'gl-tooltip');

      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe('Profile is being used by this on-demand scan');
    });
  });

  describe('profile select button', () => {
    it('should not shown when allowSelection is false', () => {
      createComponent({
        propsData: {
          ...propsData,
          allowSelection: false,
        },
      });
      expect(findProfileSelectBtn().exists()).toBe(false);
    });

    it('should not be disabled when profile is not selected', () => {
      createComponent({
        propsData: {
          ...propsData,
          isProfileSelected: false,
        },
      });
      expect(findProfileSelectBtn().props('disabled')).toBe(false);
    });
  });

  describe.each`
    profileType     | expectedResult
    ${SCANNER_TYPE} | ${__('Edit scanner profile')}
    ${SITE_TYPE}    | ${__('Edit site profile')}
  `('Edit button title', ({ profileType, expectedResult }) => {
    beforeEach(() => {
      createComponent({
        propsData: {
          ...propsData,
          profileType,
        },
      });
    });

    it('should render correct header based on mode', () => {
      expect(findProfileEditBtn().attributes('title')).toEqual(expectedResult);
    });
  });
});
