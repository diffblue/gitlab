import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import $ from 'jquery';
import { setCookie } from '~/lib/utils/common_utils';

export default class SidebarContext {
  constructor() {
    const $issuableSidebar = $('.js-issuable-update');

    $issuableSidebar
      .off('click', '.js-sidebar-dropdown-toggle')
      .on('click', '.js-sidebar-dropdown-toggle', function onClickEdit(e) {
        e.preventDefault();
        const $block = $(this).parents('.js-labels-block');
        const $selectbox = $block.find('.js-selectbox');

        // We use `:visible` to detect element visibility
        // since labels dropdown itself is handled by
        // labels_select.js which internally uses
        // $.hide() & $.show() to toggle elements
        // which requires us to use `display: none;`
        // in `labels_select/base.vue` as well.
        // see: https://gitlab.com/gitlab-org/gitlab/merge_requests/4773#note_61844731
        if ($selectbox.length) {
          const isVisible = Boolean($selectbox.get(0).offsetParent);
          $selectbox.toggle(!isVisible);
          $block.find('.js-value').toggle(isVisible);

          if ($selectbox.get(0).offsetParent) {
            setTimeout(() => $block.find('.js-label-select').trigger('click'), 0);
          }
        }
      });

    window.addEventListener('beforeunload', () => {
      // collapsed_gutter cookie hides the sidebar
      const bpBreakpoint = bp.getBreakpointSize();
      if (bpBreakpoint === 'xs' || bpBreakpoint === 'sm' || bpBreakpoint === 'md') {
        setCookie('collapsed_gutter', true);
      }
    });
  }
}
