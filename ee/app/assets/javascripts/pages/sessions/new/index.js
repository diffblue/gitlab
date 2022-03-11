import '~/pages/sessions/new/index';

if (gon.features.arkoseLabsLoginChallenge) {
  import('ee/arkose_labs/arkose_labs')
    .then(({ ArkoseLabs }) => {
      // eslint-disable-next-line no-new
      new ArkoseLabs();
    })
    .catch(() => {});
}
