import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchExceptionsToggleList from 'ee/security_orchestration/components/policy_drawer/branch_exceptions_toggle_list.vue';

const MOCK_BRANCH_EXCEPTIONS = (count = 10) =>
  [...Array(count).keys()].map((i) => `test=branch-${i}`);

describe('BranchExceptionsToggleList', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(BranchExceptionsToggleList, {
      propsData: {
        branchExceptions: MOCK_BRANCH_EXCEPTIONS(),
        ...propsData,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findToggleButton = () => wrapper.findComponent(GlButton);
  const findAllBranchExceptions = () => wrapper.findAllByTestId('branch-item');
  const findExceptionList = () => wrapper.findByTestId('exception-list');

  it('should hide extra exceptions when length is over 5', () => {
    expect(findToggleButton().exists()).toBe(true);
    expect(findToggleButton().text()).toBe('+ 5 more');
    expect(findAllBranchExceptions()).toHaveLength(5);
    expect(findExceptionList().classes()).toContain('gl-list-style-none');
  });

  it('should show all branches when show all is clicked', async () => {
    expect(findAllBranchExceptions()).toHaveLength(5);

    findToggleButton().vm.$emit('click');
    await nextTick();

    expect(findAllBranchExceptions()).toHaveLength(10);
    expect(findToggleButton().text()).toBe('Hide extra branches');
  });

  it('should not render toggle button when there are less than 5 exceptions', () => {
    createComponent({
      propsData: {
        branchExceptions: MOCK_BRANCH_EXCEPTIONS(3),
      },
    });

    expect(findAllBranchExceptions()).toHaveLength(3);
    expect(findToggleButton().exists()).toBe(false);
  });

  it('should render bullet style lists', () => {
    createComponent({
      propsData: {
        bulletStyle: true,
      },
    });

    expect(findExceptionList().classes()).not.toContain('gl-list-style-none');
  });
});
