import ShortcutsEpic from 'ee/behaviors/shortcuts/shortcuts_epic';
import initEpicApp from 'ee/epic/epic_bundle';
import initNotesApp from '~/notes';
import ZenMode from '~/zen_mode';
import initAwardsApp from '~/emoji/awards_app';

initNotesApp();
initEpicApp();

import('ee/linked_epics/linked_epics_bundle')
  .then((m) => m.default())
  .catch(() => {});

requestIdleCallback(() => {
  new ShortcutsEpic(); // eslint-disable-line no-new
  initAwardsApp(document.getElementById('js-vue-awards-block'));
  new ZenMode(); // eslint-disable-line no-new
});
