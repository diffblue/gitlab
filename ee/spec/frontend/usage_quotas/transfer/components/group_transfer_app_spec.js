import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupTransferApp from 'ee/usage_quotas/transfer/components/group_transfer_app.vue';
import { USAGE_BY_MONTH_HEADER, USAGE_BY_PROJECT_HEADER } from 'ee/usage_quotas/constants';

describe('GroupTransferApp', () => {
  let wrapper;

  const defaultProvide = {
    fullPath: 'h5bp',
  };

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(GroupTransferApp, {
      provide: { ...defaultProvide, ...provide },
    });
  };

  it('renders `Usage by month` heading', () => {
    createComponent();

    expect(wrapper.findByRole('heading', { name: USAGE_BY_MONTH_HEADER }).exists()).toBe(true);
  });

  it('renders `Usage by project` heading', () => {
    createComponent();

    expect(wrapper.findByRole('heading', { name: USAGE_BY_PROJECT_HEADER }).exists()).toBe(true);
  });
});
