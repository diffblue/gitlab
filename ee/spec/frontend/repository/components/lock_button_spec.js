import { GlButton, GlModal } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import LockButton from 'ee_component/repository/components/lock_button.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import lockPathMutation from '~/repository/mutations/lock_path.mutation.graphql';

const DEFAULT_PROPS = {
  name: 'some_file.js',
  path: 'some/path',
  projectPath: 'some/project/path',
  isLocked: false,
  canLock: true,
};

describe('LockButton component', () => {
  const localVue = createLocalVue();
  let wrapper;

  const createMockApolloProvider = (resolverMock) => {
    localVue.use(VueApollo);
    return createMockApollo([[lockPathMutation, resolverMock]]);
  };

  const createComponent = (props = {}, lockMutation = jest.fn()) => {
    wrapper = shallowMount(LockButton, {
      localVue,
      apolloProvider: createMockApolloProvider(lockMutation),
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('lock button', () => {
    let lockMutationMock;
    const mockEvent = { preventDefault: jest.fn() };
    const findLockButton = () => wrapper.findComponent(GlButton);
    const findModal = () => wrapper.findComponent(GlModal);
    const clickSubmit = () => findModal().vm.$emit('primary', mockEvent);
    const clickHide = () => findModal().vm.$emit('hide', mockEvent);

    beforeEach(() => {
      lockMutationMock = jest.fn();
    });

    it('disables the lock button if canLock is set to false', () => {
      createComponent({ canLock: false });

      expect(findLockButton().props('disabled')).toBe(true);
    });

    it.each`
      isLocked | label
      ${false} | ${'Lock'}
      ${true}  | ${'Unlock'}
    `('renders the correct button labels', ({ isLocked, label }) => {
      createComponent({ isLocked });

      expect(findLockButton().text()).toBe(label);
    });

    it('passes the correct prop if lockLoading is set to true', async () => {
      createComponent();
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ lockLoading: true });

      await nextTick();

      expect(findLockButton().props('loading')).toBe(true);
    });

    it('displays a confirm modal when the lock button is clicked', () => {
      createComponent();
      findLockButton().vm.$emit('click');
      expect(findModal().text()).toBe('Are you sure you want to lock some_file.js?');
    });

    it('should hide the confirm modal when a hide action is triggered', () => {
      createComponent();
      findLockButton().vm.$emit('click');
      expect(wrapper.vm.isModalVisible).toBe(true);
      clickHide();
      expect(wrapper.vm.isModalVisible).toBe(false);
    });

    it('executes a lock mutation once lock is confirmed', async () => {
      createComponent({}, lockMutationMock);
      findLockButton().vm.$emit('click');
      clickSubmit();
      expect(lockMutationMock).toHaveBeenCalledWith({
        filePath: 'some/path',
        lock: true,
        projectPath: 'some/project/path',
      });
    });

    it('does not execute a lock mutation if lock not confirmed', () => {
      createComponent({}, lockMutationMock);
      findLockButton().vm.$emit('click');

      expect(lockMutationMock).not.toHaveBeenCalled();
    });
  });
});
