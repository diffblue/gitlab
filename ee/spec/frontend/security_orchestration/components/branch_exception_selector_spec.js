import { GlSprintf, GlCollapsibleListbox } from '@gitlab/ui';
import BranchExceptionSelector from 'ee/security_orchestration/components/branch_exception_selector.vue';
import ProjectBranchSelector from 'ee/vue_shared/components/branches_selector/project_branch_selector.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { NO_EXCEPTION_KEY, EXCEPTION_KEY } from 'ee/security_orchestration/components/constants';

describe('BranchExceptionSelector', () => {
  let wrapper;

  const NAMESPACE_PATH = 'gitlab/project';
  const MOCK_BRANCHES = ['main', 'test'];

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(BranchExceptionSelector, {
      propsData,
      provide: {
        namespacePath: NAMESPACE_PATH,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findNamespaceTypeListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findProjectBranchSelector = () => wrapper.findComponent(ProjectBranchSelector);

  describe('default rendering states', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should display no exception mode by default', () => {
      expect(findNamespaceTypeListbox().props('selected')).toBe(NO_EXCEPTION_KEY);
      expect(findProjectBranchSelector().exists()).toBe(false);
    });

    it('should display branches listbox for  exceptions', async () => {
      await findNamespaceTypeListbox().vm.$emit('select', EXCEPTION_KEY);
      expect(findProjectBranchSelector().exists()).toBe(true);
    });
  });

  describe('existing branch exceptions', () => {
    it('should display saved exceptions', () => {
      createComponent({
        propsData: { selectedExceptions: MOCK_BRANCHES },
      });

      expect(findProjectBranchSelector().props('selected')).toEqual(MOCK_BRANCHES);
      expect(findProjectBranchSelector().exists()).toBe(true);
    });
  });

  describe('exception selection', () => {
    it('should select exceptions', async () => {
      createComponent();

      await findNamespaceTypeListbox().vm.$emit('select', EXCEPTION_KEY);

      await findProjectBranchSelector().vm.$emit('select', MOCK_BRANCHES);

      expect(wrapper.emitted('select')).toEqual([[{ branch_exceptions: MOCK_BRANCHES }]]);
    });
  });
});
