import '~/pages/sessions/new/index';

if (gon.features?.arkoseLabsLoginChallenge) {
  import('ee/arkose_labs')
    .then(({ setupArkoseLabs }) => {
      setupArkoseLabs();
    })
    .catch((e) => {
      throw e;
    });
}
