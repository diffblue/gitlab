import DastScannerProfileList from 'ee/security_configuration/dast_profiles/components/dast_scanner_profiles_list.vue';
import DastSiteProfileList from 'ee/security_configuration/dast_profiles/components/dast_site_profiles_list.vue';
import { dastProfilesDeleteResponse } from 'ee/security_configuration/dast_profiles/graphql/cache_utils';
import dastScannerProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql';
import dastScannerProfilesDelete from 'ee/security_configuration/dast_profiles/graphql/dast_scanner_profiles_delete.mutation.graphql';
import dastSiteProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql';
import dastSiteProfilesDelete from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles_delete.mutation.graphql';
import { s__ } from '~/locale';

export const getProfileSettings = ({ createNewProfilePaths }) => ({
  siteProfiles: {
    profileType: 'siteProfiles',
    tabName: 'site-profiles',
    createNewProfilePath: createNewProfilePaths.siteProfile,
    graphQL: {
      query: dastSiteProfilesQuery,
      deletion: {
        mutation: dastSiteProfilesDelete,
        optimisticResponse: dastProfilesDeleteResponse({
          mutationName: 'siteProfilesDelete',
          payloadTypeName: 'DastSiteProfileDeletePayload',
        }),
      },
    },
    component: DastSiteProfileList,
    tableFields: [
      { label: s__('DastProfiles|Site name'), key: 'profileName' },
      { label: s__('DastProfiles|URL'), key: 'targetUrl' },
      { label: s__('DastProfiles|Validation status'), key: 'validationStatus' },
    ],
    i18n: {
      createNewLinkText: s__('DastProfiles|Site profile'),
      name: s__('DastProfiles|Site profiles'),
      errorMessages: {
        fetchNetworkError: s__(
          'DastProfiles|Could not fetch site profiles. Please refresh the page, or try again later.',
        ),
        deletionNetworkError: s__(
          'DastProfiles|Could not delete site profile. Please refresh the page, or try again later.',
        ),
        deletionBackendError: s__('DastProfiles|Could not delete site profiles:'),
      },
      noProfilesMessage: s__('DastProfiles|No site profiles created yet'),
    },
  },
  scannerProfiles: {
    profileType: 'scannerProfiles',
    tabName: 'scanner-profiles',
    createNewProfilePath: createNewProfilePaths.scannerProfile,
    graphQL: {
      query: dastScannerProfilesQuery,
      deletion: {
        mutation: dastScannerProfilesDelete,
        optimisticResponse: dastProfilesDeleteResponse({
          mutationName: 'scannerProfilesDelete',
          payloadTypeName: 'DastScannerProfileDeletePayload',
        }),
      },
    },
    component: DastScannerProfileList,
    tableFields: [
      { label: s__('DastProfiles|Scanner name'), key: 'profileName' },
      { label: s__('DastProfiles|Scan mode'), key: 'scanType' },
    ],
    i18n: {
      createNewLinkText: s__('DastProfiles|Scanner profile'),
      name: s__('DastProfiles|Scanner profiles'),
      errorMessages: {
        fetchNetworkError: s__(
          'DastProfiles|Could not fetch scanner profiles. Please refresh the page, or try again later.',
        ),
        deletionNetworkError: s__(
          'DastProfiles|Could not delete scanner profile. Please refresh the page, or try again later.',
        ),
        deletionBackendError: s__('DastProfiles|Could not delete scanner profiles:'),
      },
      noProfilesMessage: s__('DastProfiles|No scanner profiles created yet'),
    },
  },
});
