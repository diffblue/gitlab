import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ApprovalsAuth from 'ee/vue_merge_request_widget/components/approvals/approvals_auth.vue';

const TEST_PASSWORD = 'password';

// For some reason, the `Promise.resolve` needs to be deferred
// or the timing doesn't work.
const waitForTick = (done) => Promise.resolve().then(done).catch(done.fail);

describe('Approval auth component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ApprovalsAuth, {
      propsData: {
        ...props,
        modalId: 'testid',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findInput = () => wrapper.find('input[type=password]');
  const findErrorMessage = () => wrapper.find('.gl-field-error');

  describe('when created', () => {
    beforeEach((done) => {
      createComponent();
      waitForTick(done);
    });

    it('password input control is rendered', () => {
      expect(wrapper.find('input').exists()).toBe(true);
    });

    it('does not disable approve button', () => {
      const attrs = wrapper.attributes();

      expect(attrs['ok-disabled']).toBeUndefined();
    });

    it('does not show error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });

    it('does not emit anything', () => {
      expect(wrapper.emitted()).toEqual({});
    });
  });

  describe('when approve clicked', () => {
    beforeEach((done) => {
      createComponent();
      waitForTick(done);
    });

    it('emits the approve event', (done) => {
      findInput().setValue(TEST_PASSWORD);
      wrapper.findComponent(GlModal).vm.$emit('ok', { preventDefault: () => null });
      waitForTick(done);

      expect(wrapper.emitted().approve).toEqual([[TEST_PASSWORD]]);
    });
  });

  describe('when isApproving is true', () => {
    beforeEach((done) => {
      createComponent({ isApproving: true });
      waitForTick(done);
    });

    it('disables the approve button', () => {
      const attrs = wrapper.attributes();

      expect(attrs['ok-disabled']).toEqual('true');
    });
  });

  describe('when hasError is true', () => {
    beforeEach((done) => {
      createComponent({ hasError: true });
      waitForTick(done);
    });

    it('shows the invalid password message', () => {
      expect(findErrorMessage().exists()).toBe(true);
    });
  });
});
