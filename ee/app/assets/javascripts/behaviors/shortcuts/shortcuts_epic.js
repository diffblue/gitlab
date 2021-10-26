import $ from 'jquery';
import Cookies from 'js-cookie';
import Mousetrap from 'mousetrap';
import {
  keysFor,
  ISSUABLE_CHANGE_LABEL,
  ISSUABLE_COMMENT_OR_REPLY,
  ISSUABLE_EDIT_DESCRIPTION,
} from '~/behaviors/shortcuts/keybindings';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import { parseBoolean } from '~/lib/utils/common_utils';

export default class ShortcutsEpic extends ShortcutsIssuable {
  constructor() {
    super();

    const $issuableSidebar = $('.js-issuable-update');

    Mousetrap.bind(keysFor(ISSUABLE_CHANGE_LABEL), () =>
      ShortcutsEpic.openSidebarDropdown($issuableSidebar.find('.js-labels-block')),
    );
    Mousetrap.bind(keysFor(ISSUABLE_COMMENT_OR_REPLY), ShortcutsIssuable.replyWithSelectedText);
    Mousetrap.bind(keysFor(ISSUABLE_EDIT_DESCRIPTION), ShortcutsIssuable.editIssue);
  }

  static openSidebarDropdown($block) {
    if (gon.features?.labelsWidget) {
      document.dispatchEvent(new Event('toggleSidebarRevealLabelsDropdown'));
      return;
    }
    if (parseBoolean(Cookies.get('collapsed_gutter'))) {
      document.dispatchEvent(new Event('toggleSidebarRevealLabelsDropdown'));
    } else {
      $block.find('.js-sidebar-dropdown-toggle').get(0).dispatchEvent(new Event('click'));
    }
  }
}
