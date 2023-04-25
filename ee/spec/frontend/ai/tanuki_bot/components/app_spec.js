import { GlDrawer } from '@gitlab/ui';
import { nextTick } from 'vue';
import TanukiBotChatApp from 'ee/ai/tanuki_bot/components/app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { helpCenterState } from '~/super_sidebar/constants';

describe('TanukiBotChatApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(TanukiBotChatApp, {
      stubs: {
        GlDrawer,
        Portal: {
          template: '<div><slot></slot></div>',
        },
      },
    });
  };

  const findGlDrawer = () => wrapper.findComponent(GlDrawer);
  const findGlDrawerBackdrop = () => wrapper.findByTestId('tanuki-bot-chat-drawer-backdrop');

  describe('GlDrawer interactions', () => {
    beforeEach(() => {
      createComponent();
      helpCenterState.showTanukiBotChatDrawer = true;
    });

    it('closes the drawer when GlDrawer emits @close', async () => {
      findGlDrawer().vm.$emit('close');

      await nextTick();

      expect(findGlDrawer().props('open')).toBe(false);
    });
  });

  describe('GlDrawer Backdrop', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render when drawer is closed', () => {
      expect(findGlDrawerBackdrop().exists()).toBe(false);
    });

    describe('when open is true', () => {
      beforeEach(() => {
        createComponent();
        helpCenterState.showTanukiBotChatDrawer = true;
      });

      it('does render', () => {
        expect(findGlDrawerBackdrop().exists()).toBe(true);
      });

      it('when clicked, calls closeDrawer', async () => {
        findGlDrawerBackdrop().trigger('click');

        await nextTick();

        expect(findGlDrawer().props('open')).toBe(false);
      });
    });
  });
});
