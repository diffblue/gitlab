import BaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/base_layout_component.vue';
import LicenseFilter from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/license_filter.vue';
import { UNKNOWN_LICENSE } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { licenseScanBuildRule } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/rules';

describe('LicenseFilter', () => {
  let wrapper;

  const DEFAULT_PROPS = { initRule: licenseScanBuildRule() };
  const APACHE_LICENSE = 'Apache 2.0 License';
  const MIT_LICENSE = 'MIT License';
  const UPDATED_RULE = (licenses) => ({
    ...licenseScanBuildRule(),
    branches: [],
    match_on_inclusion: false,
    license_types: licenses,
    license_states: ['newly_detected', 'detected'],
  });
  const parsedSoftwareLicenses = [APACHE_LICENSE, MIT_LICENSE].map((l) => ({ text: l, value: l }));
  const allLicenses = [...parsedSoftwareLicenses, UNKNOWN_LICENSE];

  const createComponent = (props = DEFAULT_PROPS) => {
    wrapper = shallowMountExtended(LicenseFilter, {
      propsData: {
        ...props,
      },
      provide: {
        parsedSoftwareLicenses,
      },
      stubs: {
        BaseLayoutComponent,
      },
    });
  };

  const findMatchTypeListBox = () => wrapper.findByTestId('match-type-select');
  const findLicenseTypeListBox = () => wrapper.findByTestId('license-type-select');

  describe('default rule', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits a "changed" event when the matchType is updated', async () => {
      const matchType = false;
      await findMatchTypeListBox().vm.$emit('select', matchType);
      expect(wrapper.emitted('changed')).toStrictEqual([[{ match_on_inclusion: matchType }]]);
    });

    describe('license type list box', () => {
      it('displays the default toggle text', () => {
        expect(findLicenseTypeListBox()).toBeDefined();
        expect(findLicenseTypeListBox().props('toggleText')).toBe('Select license types');
      });

      it('emits a "changed" event when the licenseType is updated', async () => {
        await findLicenseTypeListBox().vm.$emit('select', MIT_LICENSE);
        expect(wrapper.emitted('changed')).toStrictEqual([[{ license_types: MIT_LICENSE }]]);
      });

      it('displays all licenses', () => {
        expect(findLicenseTypeListBox().props('items')).toStrictEqual(allLicenses);
      });

      it('filters the licenses when searching', async () => {
        const listBox = findLicenseTypeListBox();
        await listBox.vm.$emit('search', APACHE_LICENSE);
        expect(listBox.props('items')).toStrictEqual([
          { value: APACHE_LICENSE, text: APACHE_LICENSE },
        ]);
      });
    });

    describe('updated rule', () => {
      it('displays the toggle text properly with a single license selected', () => {
        createComponent({ initRule: UPDATED_RULE([MIT_LICENSE]) });
        const listBox = findLicenseTypeListBox();
        expect(listBox.props('toggleText')).toBe(MIT_LICENSE);
      });

      it('displays the toggle text properly with multiple licenses selected', () => {
        createComponent({ initRule: UPDATED_RULE([MIT_LICENSE, APACHE_LICENSE]) });
        const listBox = findLicenseTypeListBox();
        expect(listBox.props('toggleText')).toBe('2 licenses');
      });
    });

    describe('multiple actions', () => {
      beforeEach(() => {
        createComponent();
      });

      it('can select single licence types', () => {
        findLicenseTypeListBox().vm.$emit('select', parsedSoftwareLicenses[0].value);
        expect(wrapper.emitted('changed')).toEqual([
          [expect.objectContaining({ license_types: parsedSoftwareLicenses[0].value })],
        ]);
      });

      it('can select single all licence types', () => {
        findLicenseTypeListBox().vm.$emit('select-all');
        expect(wrapper.emitted('changed')).toEqual([
          [expect.objectContaining({ license_types: allLicenses.map(({ value }) => value) })],
        ]);
      });

      it('can clear all selected licence types', () => {
        createComponent();

        findLicenseTypeListBox().vm.$emit('select-all');
        findLicenseTypeListBox().vm.$emit('reset');

        expect(wrapper.emitted('changed')[1]).toEqual([
          expect.objectContaining({ license_types: [] }),
        ]);
      });
    });
  });
});
