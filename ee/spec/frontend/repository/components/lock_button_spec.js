import { GlButton } from '@gitlab/ui';
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
    let confirmSpy;
    let lockMutationMock;
    const findLockButton = () => wrapper.find(GlButton);

    beforeEach(() => {
      confirmSpy = jest.spyOn(window, 'confirm');
      confirmSpy.mockImplementation(jest.fn());
      lockMutationMock = jest.fn();
    });

    afterEach(() => confirmSpy.mockRestore());

    it('does not render if canLock is set to false', () => {
      createComponent({ canLock: false });

      expect(findLockButton().exists()).toBe(false);
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
      wrapper.setData({ lockLoading: true });

      await nextTick();

      expect(findLockButton().props('loading')).toBe(true);
    });

    it('displays a confirm dialog when the lock button is clicked', () => {
      createComponent();
      findLockButton().vm.$emit('click');

      expect(confirmSpy).toHaveBeenCalledWith('Are you sure you want to lock some_file.js?');
    });

    it('executes a lock mutation once lock is confirmed', () => {
      confirmSpy.mockReturnValue(true);
      createComponent({}, lockMutationMock);
      findLockButton().vm.$emit('click');

      expect(lockMutationMock).toHaveBeenCalledWith({
        filePath: 'some/path',
        lock: true,
        projectPath: 'some/project/path',
      });
    });

    it('does not execute a lock mutation if lock not confirmed', () => {
      confirmSpy.mockReturnValue(false);
      createComponent({}, lockMutationMock);
      findLockButton().vm.$emit('click');

      expect(lockMutationMock).not.toHaveBeenCalled();
    });
  });
});
