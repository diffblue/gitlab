import { __, s__ } from '~/locale';
import activateSubscriptionMutation from './graphql/mutations/activate_subscription.mutation.graphql';
import getCurrentLicense from './graphql/queries/get_current_license.query.graphql';
import getLicenseHistory from './graphql/queries/get_license_history.query.graphql';

export const subscriptionMainTitle = s__('SuperSonics|Your subscription');
export const subscriptionActivationNotificationText = s__(
  `SuperSonics|Your subscription was successfully activated. You can see the details below.`,
);
export const subscriptionActivationInsertCode = __(
  "If you've purchased or renewed your subscription and have an activation code, please enter it below to start the activation process.",
);
export const howToActivateSubscription = s__(
  'SuperSonics|Learn how to %{linkStart}activate your subscription%{linkEnd}.',
);
export const activateLabel = s__('SuperSonics|Activate');
export const activateSubscription = s__('SuperSonics|Activate subscription');
export const activateCloudLicense = s__('SuperSonics|Activate cloud license');
export const noActiveSubscription = s__(`SuperSonics|You do not have an active subscription`);
export const subscriptionDetailsHeaderText = s__('SuperSonics|Subscription details');
export const licensedToHeaderText = s__('SuperSonics|Licensed to');
export const manageSubscriptionButtonText = s__('SuperSonics|Manage');
export const syncSubscriptionButtonText = s__('SuperSonics|Sync subscription details');
export const copySubscriptionIdButtonText = __('Copy');
export const licenseFileText = __('License file');
export const cloudLicenseText = s__('SuperSonics|Cloud license');
export const usersInSubscriptionUnlimited = __('Unlimited');
export const detailsLabels = {
  address: __('Address'),
  company: __('Company'),
  email: __('Email'),
  id: s__('SuperSonics|ID'),
  lastSync: s__('SuperSonics|Last Sync'),
  name: __('Name'),
  plan: s__('SuperSonics|Plan'),
  expiresAt: s__('SuperSonics|Renews'),
  startsAt: s__('SuperSonics|Started'),
};

export const removeLicense = __('Remove license');
export const removeLicenseConfirm = __('Are you sure you want to remove the license?');
export const uploadLicense = __('Upload license');
export const uploadLicenseFile = s__('SuperSonics|Upload a license file');
export const billableUsersTitle = s__('SuperSonics|Billable users');
export const maximumUsersTitle = s__('SuperSonics|Maximum users');
export const usersInSubscriptionTitle = s__('SuperSonics|Users in subscription');
export const usersOverSubscriptionTitle = s__('SuperSonics|Users over subscription');
export const billableUsersText = s__(
  'SuperSonics|This is the number of %{billableUsersLinkStart}billable users%{billableUsersLinkEnd} on your installation, and this is the minimum number you need to purchase when you renew your license.',
);
export const maximumUsersText = s__(
  'SuperSonics|This is the highest peak of users on your installation since the license started.',
);
export const usersInSubscriptionText = s__(
  `SuperSonics|Users with a Guest role or those who don't belong to a Project or Group will not use a seat from your license.`,
);
export const usersOverSubscriptionText = s__(
  `SuperSonics|You'll be charged for %{trueUpLinkStart}users over license%{trueUpLinkEnd} on a quarterly or annual basis, depending on the terms of your agreement.`,
);
export const subscriptionTable = {
  activatedAt: s__('SuperSonics|Activated on'),
  expiresOn: s__('SuperSonics|Expires on'),
  seats: s__('SuperSonics|Seats'),
  startsAt: s__('SuperSonics|Valid From'),
  title: __('Subscription History'),
  type: s__('SuperSonics|Type'),
};
export const connectivityIssue = s__('SuperSonics|There is a connectivity issue.');
export const manualSyncPendingText = s__(
  'SuperSonics|Your subscription details will sync shortly.',
);
export const manualSyncPendingTitle = s__('SuperSonics|Sync subscription request.');
export const manualSyncFailureText = s__(
  'SuperSonics|You can no longer sync your subscription details with GitLab. Get help for the most common connectivity issues by %{connectivityHelpLinkStart}troubleshooting the activation code%{connectivityHelpLinkEnd}.',
);

export const subscriptionActivationForm = {
  activationCode: s__('SuperSonics|Activation code'),
  pasteActivationCode: s__('SuperSonics|Paste your activation code'),
  acceptTerms: s__(
    'SuperSonics|I agree that my use of the GitLab Software is subject to the Subscription Agreement located at the %{linkStart}Terms of Service%{linkEnd}, unless otherwise agreed to in writing with GitLab.',
  ),
};

export const subscriptionSyncStatus = {
  SYNC_FAILURE: 'SYNC_FAILURE',
  SYNC_PENDING: 'SYNC_PENDING',
};

export const subscriptionTypes = {
  CLOUD: 'cloud',
  LICENSE_FILE: 'license_file',
};

export const subscriptionQueries = {
  query: getCurrentLicense,
  mutation: activateSubscriptionMutation,
};

export const subscriptionHistoryQueries = {
  query: getLicenseHistory,
};

export const trialCard = {
  title: s__('SuperSonics|Free trial'),
  description: s__(
    'SuperSonics|You can start a free trial of GitLab Ultimate without any obligation or payment details.',
  ),
  startTrial: s__('SuperSonics|Start free trial'),
};

export const buySubscriptionCard = {
  title: s__('SuperSonics|Subscription'),
  description: s__(
    'SuperSonics|Ready to get started? A GitLab plan is ideal for scaling organizations and for multi team usage.',
  ),
  buttonLabel: s__('SuperSonics|Buy subscription'),
};

export const INVALID_CODE_ERROR_MESSAGE = 'invalid activation code';
export const CONNECTIVITY_ERROR = 'CONNECTIVITY_ERROR';
export const INVALID_CODE_ERROR = 'INVALID_CODE_ERROR';
export const generalActivationErrorTitle = s__(
  'SuperSonics|An error occurred while activating your subscription.',
);
export const generalActivationErrorMessage = s__(
  'SuperSonics|You can learn more about %{activationLinkStart}activating your subscription%{activationLinkEnd}. If you need further assistance, please %{supportLinkStart}contact GitLab Support%{supportLinkEnd}.',
);
export const invalidActivationCode = s__(
  'SuperSonics|The activation code is not valid. Please make sure to copy it exactly from the Customers Portal or confirmation email. Learn more about %{linkStart}activating your subscription%{linkEnd}.',
);
export const connectivityErrorAlert = {
  subtitle: s__(
    'SuperSonics|To activate your subscription, connect to GitLab servers through the %{linkStart}Cloud Licensing%{linkEnd} service, a hassle-free way to manage your subscription.',
  ),
  helpText: s__(
    'SuperSonics|Get help for the most common connectivity issues by %{linkStart}troubleshooting the activation code%{linkEnd}.',
  ),
};
export const supportLink = 'https://about.gitlab.com/support/#contact-support';
export const subscriptionBannerTitle = s__('SuperSonics|Cloud licensing');
export const subscriptionBannerText = s__(
  "SuperSonics|Cloud licensing is now available. It's an easier way to activate instances and manage subscriptions. Read more about it in our %{blogPostLinkStart}blog post%{blogPostLinkEnd}. Activation codes are available in the %{portalLinkStart}Customers Portal%{portalLinkEnd}.",
);
export const subscriptionBannerBlogPostUrl =
  'https://about.gitlab.com/blog/2021/07/20/improved-billing-and-subscription-management/';
export const exportLicenseUsageBtnText = s__('SuperSonics|Export license usage file');
