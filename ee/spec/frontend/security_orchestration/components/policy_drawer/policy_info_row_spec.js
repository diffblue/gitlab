import PolicyInfoRow from 'ee/security_orchestration/components/policy_drawer/policy_info_row.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('PolicyInfoRow component', () => {
  let wrapper;

  const findLabel = () => wrapper.findByTestId('label');
  const findContent = () => wrapper.findByTestId('content');

  const factory = () => {
    wrapper = shallowMountExtended(PolicyInfoRow, {
      propsData: {
        label: 'Some label',
      },
      slots: {
        default: 'Some <a href="#">content</a>',
      },
    });
  };

  beforeEach(() => {
    factory();
  });

  it('renders the label', () => {
    expect(findLabel().text()).toBe('Some label');
  });

  it('renders the content', () => {
    expect(findContent().text()).toBe('Some content');
  });
});
