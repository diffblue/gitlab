import { GlEmptyState, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyState, { i18n } from 'ee/remote_development/components/list/empty_state.vue';
import { ROUTES } from 'ee/remote_development/constants';

const SVG_PATH = '/assets/illustrations/empty_states/empty_workspaces.svg';

describe('remote_development/components/list/empty_state.vue', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = () => {
    wrapper = shallowMount(EmptyState, {
      provide: {
        emptyStateSvgPath: SVG_PATH,
      },
      stubs: {
        GlEmptyState,
      },
    });
  };

  describe('when no workspaces exist', () => {
    it('should render empty workspace state', () => {
      createComponent();

      expect(findEmptyState().props()).toMatchObject({
        title: i18n.title,
        description: i18n.description,
        svgPath: SVG_PATH,
      });
    });

    it('displays a button that navigates to the new workspace page', () => {
      createComponent();

      const button = findEmptyState().findComponent(GlButton);

      expect(button.props()).toMatchObject({
        variant: 'confirm',
      });
      expect(button.attributes()).toMatchObject({
        to: ROUTES.create,
      });
    });
  });
});
