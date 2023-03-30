import '~/pages/projects/usage_quotas';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';

if (window.gon.features?.dataTransferMonitoring) {
  import('ee/usage_quotas/transfer')
    .then(({ initProjectTransferApp }) => {
      initProjectTransferApp();
    })
    .catch(() => {
      createAlert({
        message: s__(
          'UsageQuotas|An error occurred loading the transfer data. Please refresh the page to try again.',
        ),
      });
    });
}
