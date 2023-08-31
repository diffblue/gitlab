import { GlSprintf } from '@gitlab/ui';
import SectionLayout from 'ee/security_orchestration/components/policy_editor/section_layout.vue';
import GroupDastProfileSelector from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_filters/group_dast_profile_selector.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('GroupDastProfileSelector', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(GroupDastProfileSelector, {
      propsData: {
        ...props,
      },
      stubs: {
        SectionLayout,
        GlSprintf,
      },
    });
  };

  const findScannerProfileInput = () => wrapper.findByTestId('scan-profile-selection');
  const findSiteProfileInput = () => wrapper.findByTestId('site-profile-selection');

  it('renders input fields for scanner and site profiles', () => {
    createComponent();

    expect(findScannerProfileInput().exists()).toBe(true);
    expect(findSiteProfileInput().exists()).toBe(true);

    expect(findScannerProfileInput().attributes('placeholder')).toBe(
      GroupDastProfileSelector.i18n.selectedScannerProfilePlaceholder,
    );
    expect(findSiteProfileInput().attributes('placeholder')).toBe(
      GroupDastProfileSelector.i18n.selectedSiteProfilePlaceholder,
    );
  });

  it.each`
    findProfile                | testValue | savedScannerProfileName | savedSiteProfileName | emittedValue
    ${findScannerProfileInput} | ${'test'} | ${null}                 | ${null}              | ${{ siteProfile: '', scannerProfile: 'test' }}
    ${findSiteProfileInput}    | ${'test'} | ${null}                 | ${null}              | ${{ siteProfile: 'test', scannerProfile: '' }}
    ${findScannerProfileInput} | ${'test'} | ${null}                 | ${'test2'}           | ${{ siteProfile: 'test2', scannerProfile: 'test' }}
    ${findSiteProfileInput}    | ${'test'} | ${'test2'}              | ${null}              | ${{ siteProfile: 'test', scannerProfile: 'test2' }}
    ${findSiteProfileInput}    | ${'test'} | ${'test1'}              | ${'test2'}           | ${{ siteProfile: 'test', scannerProfile: 'test1' }}
  `(
    'emits changes of profile names',
    async ({
      findProfile,
      testValue,
      savedScannerProfileName,
      savedSiteProfileName,
      emittedValue,
    }) => {
      createComponent({
        savedScannerProfileName,
        savedSiteProfileName,
      });

      await findProfile().vm.$emit('input', testValue);
      expect(wrapper.emitted('set-profile')).toEqual([[emittedValue]]);
    },
  );

  it('displays saved profiles names', () => {
    const siteProfileName = 'siteProfileName';
    const scannerProfileName = 'scannerProfileName';

    createComponent({
      savedScannerProfileName: scannerProfileName,
      savedSiteProfileName: siteProfileName,
    });

    expect(findScannerProfileInput().attributes('value')).toBe(scannerProfileName);
    expect(findSiteProfileInput().attributes('value')).toBe(siteProfileName);
  });
});
