import { GlButton, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';

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
  let wrapper;

  const createMockApolloProvider = (resolverMock) => {
    Vue.use(VueApollo);
    return createMockApollo([[lockPathMutation, resolverMock]]);
  };

  const createComponent = (props = {}, lockMutation = jest.fn()) => {
    wrapper = shallowMount(LockButton, {
      apolloProvider: createMockApolloProvider(lockMutation),
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });
  };

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
    `('renders the $label button label', ({ isLocked, label }) => {
      createComponent({ isLocked });

      expect(findLockButton().text()).toContain(label);
    });

    it('sets loading prop to true when LockButton was clicked', async () => {
      createComponent();
      findLockButton().vm.$emit('click');
      await clickSubmit();

      expect(findLockButton().props('loading')).toBe(true);
    });

    it('displays a confirm modal when the lock button is clicked', () => {
      createComponent();
      findLockButton().vm.$emit('click');
      expect(findModal().text()).toBe('Are you sure you want to lock some_file.js?');
    });

    it('should hide the confirm modal when a hide action is triggered', async () => {
      createComponent();
      await findLockButton().vm.$emit('click');
      expect(findModal().props('visible')).toBe(true);

      await clickHide();
      expect(findModal().props('visible')).toBe(false);
    });

    it('executes a lock mutation once lock is confirmed', () => {
      lockMutationMock = jest.fn().mockRejectedValue('Test');
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
