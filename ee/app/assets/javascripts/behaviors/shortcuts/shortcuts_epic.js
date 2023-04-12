import Mousetrap from 'mousetrap';
import {
  keysFor,
  ISSUABLE_CHANGE_LABEL,
  ISSUABLE_COMMENT_OR_REPLY,
  ISSUABLE_EDIT_DESCRIPTION,
} from '~/behaviors/shortcuts/keybindings';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';

export default class ShortcutsEpic extends ShortcutsIssuable {
  constructor() {
    super();

    Mousetrap.bind(keysFor(ISSUABLE_CHANGE_LABEL), ShortcutsEpic.openSidebarDropdown);
    Mousetrap.bind(keysFor(ISSUABLE_COMMENT_OR_REPLY), ShortcutsIssuable.replyWithSelectedText);
    Mousetrap.bind(keysFor(ISSUABLE_EDIT_DESCRIPTION), ShortcutsIssuable.editIssue);
  }

  static openSidebarDropdown() {
    document.dispatchEvent(new Event('toggleSidebarRevealLabelsDropdown'));
  }
}
