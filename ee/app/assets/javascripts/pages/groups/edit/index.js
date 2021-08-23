import '~/pages/groups/edit';
import initAccessRestrictionField from 'ee/groups/settings/access_restriction_field';
import validateRestrictedIpAddress from 'ee/groups/settings/access_restriction_field/validate_ip_address';
import createFlash from '~/flash';
import { __ } from '~/locale';

initAccessRestrictionField({
  selector: '.js-allowed-email-domains',
  props: {
    placeholder: __('Enter domain'),
    regexErrorMessage: __('The domain you entered is misformatted.'),
    disallowedValueErrorMessage: __('The domain you entered is not allowed.'),
  },
});

initAccessRestrictionField({
  selector: '.js-ip-restriction',
  props: { placeholder: __('Enter IP address range') },
  qaSelector: 'ip_restriction_field',
  customValidator: validateRestrictedIpAddress,
});

const complianceFrameworksList = document.querySelector('#js-compliance-frameworks-list');

if (complianceFrameworksList) {
  (async () => {
    try {
      const { createComplianceFrameworksListApp } = await import(
        /* webpackChunkName: 'createComplianceFrameworksListApp' */ 'ee/groups/settings/compliance_frameworks/init_list'
      );
      createComplianceFrameworksListApp(complianceFrameworksList);
    } catch {
      createFlash({ message: __('An error occurred while loading a section of this page.') });
    }
  })();
}

const mergeRequestApprovalSetting = document.querySelector('#js-merge-request-approval-settings');

if (mergeRequestApprovalSetting) {
  (async () => {
    try {
      const { mountGroupApprovalSettings } = await import(
        /* webpackChunkName: 'mountGroupApprovalSettings' */ 'ee/approvals/mount_group_settings'
      );
      mountGroupApprovalSettings(mergeRequestApprovalSetting);
    } catch (error) {
      createFlash({
        message: __('An error occurred while loading a section of this page.'),
        captureError: true,
        error: `Error mounting group approval settings component: #{error.message}`,
      });
    }
  })();
}
