import { ISSUABLE_CHANGE_LABEL } from '~/behaviors/shortcuts/keybindings';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';

export default class ShortcutsTestCase extends ShortcutsIssuable {
  constructor() {
    super();

    this.bindCommand(ISSUABLE_CHANGE_LABEL, ShortcutsTestCase.openSidebarDropdown);
  }

  static openSidebarDropdown() {
    document.dispatchEvent(new Event('toggleSidebarRevealLabelsDropdown'));
  }
}
