import $ from 'jquery';
import Mousetrap from 'mousetrap';
import { keysFor, ISSUABLE_CHANGE_LABEL } from '~/behaviors/shortcuts/keybindings';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';

export default class ShortcutsTestCase extends ShortcutsIssuable {
  constructor() {
    super();

    const $issuableSidebar = $('.issuable-sidebar');

    Mousetrap.bind(keysFor(ISSUABLE_CHANGE_LABEL), () =>
      ShortcutsTestCase.openSidebarDropdown($issuableSidebar.find('.js-labels-block')),
    );
  }

  static openSidebarDropdown() {
    document.dispatchEvent(new Event('toggleSidebarRevealLabelsDropdown'));
  }
}
