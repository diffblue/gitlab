import { GlDrawer } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PreScanVerificationSidebar from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_sidebar.vue';

describe('PreScanVerificationSidebar', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = mountExtended(PreScanVerificationSidebar, {
      propsData: {
        ...propsData,
      },
      stubs: {
        GlDrawer: true,
      },
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);

  beforeEach(() => {
    createComponent();
  });

  it('should render drawer', () => {
    expect(findDrawer().exists()).toBe(true);
  });

  it('should render drawer with proper z index', () => {
    expect(findDrawer().props('zIndex')).toBe(DRAWER_Z_INDEX);
  });

  it('should close drawer', async () => {
    expect(wrapper.emitted('close')).toBeUndefined();

    findDrawer().vm.$emit('close');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });
});
