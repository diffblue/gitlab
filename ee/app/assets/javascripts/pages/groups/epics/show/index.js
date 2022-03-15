import ShortcutsEpic from 'ee/behaviors/shortcuts/shortcuts_epic';
import initEpicApp from 'ee/epic/epic_bundle';
import loadAwardsHandler from '~/awards_handler';
import initNotesApp from '~/notes';
import ZenMode from '~/zen_mode';

initNotesApp();
initEpicApp();

if (gon.features.relatedEpicsWidget) {
  import('ee/linked_epics/linked_epics_bundle')
    .then((m) => m.default())
    .catch(() => {});
}

requestIdleCallback(() => {
  const awardEmojiEl = document.getElementById('js-vue-awards-block');

  new ShortcutsEpic(); // eslint-disable-line no-new
  if (awardEmojiEl) {
    import('~/emoji/awards_app')
      .then((m) => m.default(awardEmojiEl))
      .catch(() => {});
  } else {
    loadAwardsHandler();
  }
  new ZenMode(); // eslint-disable-line no-new
});
