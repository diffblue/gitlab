import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import EmptyState, { i18n } from 'ee/remote_development/components/list/empty_state.vue';

const QUICK_START_LINK = '/user/workspace/quick_start/index.md';
const SVG_PATH = '/assets/illustrations/empty_states/empty_workspaces.svg';

describe('remote_development/components/list/empty_state.vue', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = () => {
    wrapper = shallowMount(EmptyState, {
      provide: {
        emptyStateSvgPath: SVG_PATH,
      },
    });
  };

  describe('when no workspaces exist', () => {
    it('should render empty workspace state', () => {
      createComponent();

      expect(findEmptyState().props()).toMatchObject({
        title: i18n.title,
        description: i18n.description,
        primaryButtonText: i18n.primaryButtonText,
        primaryButtonLink: helpPagePath(QUICK_START_LINK),
        svgPath: SVG_PATH,
      });
    });
  });
});
