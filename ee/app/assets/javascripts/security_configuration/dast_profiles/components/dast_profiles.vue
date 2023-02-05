<script>
import { GlDisclosureDropdown, GlTab, GlTabs } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { getLocationHash } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import * as cacheUtils from '../graphql/cache_utils';
import { getProfileSettings } from '../settings/profiles';
import DastFailedSiteValidations from './dast_failed_site_validations.vue';

export default {
  components: {
    GlDisclosureDropdown,
    GlTab,
    GlTabs,
    DastFailedSiteValidations,
  },
  props: {
    createNewProfilePaths: {
      type: Object,
      required: true,
      validator: ({ scannerProfile, siteProfile }) =>
        Boolean(scannerProfile) && Boolean(siteProfile),
    },
    projectFullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      profileTypes: {},
    };
  },
  computed: {
    profileSettings() {
      const { createNewProfilePaths } = this;

      return getProfileSettings({
        createNewProfilePaths,
      });
    },
    newProfileDisclosureItems() {
      return Object.values(this.profileSettings).map(
        ({ i18n, createNewProfilePath, profileType }) => ({
          text: i18n.createNewLinkText,
          href: createNewProfilePath,
          extraAttrs: {
            key: profileType,
          },
        }),
      );
    },
    tabIndex: {
      get() {
        const activeTabIndex = Object.values(this.profileSettings).findIndex(
          ({ tabName }) => tabName === getLocationHash(),
        );

        return Math.max(0, activeTabIndex);
      },
      set(newTabIndex) {
        const { tabName } = Object.values(this.profileSettings)[newTabIndex];

        if (tabName) {
          window.location.hash = tabName;
        }
      },
    },
  },
  created() {
    this.addSmartQueriesForEnabledProfileTypes();
  },
  methods: {
    addSmartQueriesForEnabledProfileTypes() {
      Object.values(this.profileSettings).forEach(({ profileType, graphQL: { query } }) => {
        this.makeProfileTypeReactive(profileType);

        this.$apollo.addSmartQuery(
          profileType,
          this.createQuery({
            profileType,
            query,
            variables: {
              fullPath: this.projectFullPath,
              first: this.$options.profilesPerPage,
            },
          }),
        );
      });
    },
    makeProfileTypeReactive(profileType) {
      this.$set(this.profileTypes, profileType, {
        profiles: [],
        pageInfo: {},
        errorMessage: '',
        errorDetails: [],
      });
    },
    hasMoreProfiles(profileType) {
      return this.profileTypes[profileType]?.pageInfo?.hasNextPage;
    },
    isLoadingProfiles(profileType) {
      return this.$apollo.queries[profileType].loading;
    },
    createQuery({ profileType, query, variables }) {
      return {
        query,
        variables,
        manual: true,
        result({ data, error }) {
          if (!error) {
            const { project } = data;
            const pageInfo = project?.[profileType].pageInfo;

            this.profileTypes[profileType].profiles = project?.[profileType]?.nodes;
            this.profileTypes[profileType].pageInfo = pageInfo;
          }
        },
        error(error) {
          this.handleError({
            profileType,
            exception: error,
            message: this.profileSettings[profileType].i18n.errorMessages.fetchNetworkError,
          });
        },
      };
    },
    handleError({ profileType, exception, message = '', details = [] }) {
      Sentry.captureException(exception);
      this.profileTypes[profileType].errorMessage = message;
      this.profileTypes[profileType].errorDetails = details;
    },
    resetErrors(profileType) {
      this.profileTypes[profileType].errorMessage = '';
      this.profileTypes[profileType].errorDetails = [];
    },
    fetchMoreProfiles(profileType) {
      const {
        $apollo,
        profileSettings: {
          [profileType]: { i18n },
        },
      } = this;
      const { pageInfo } = this.profileTypes[profileType];

      this.resetErrors(profileType);

      $apollo.queries[profileType]
        .fetchMore({
          variables: { after: pageInfo.endCursor },
        })
        .catch((error) => {
          this.handleError({
            profileType,
            exception: error,
            message: i18n.errorMessages.fetchNetworkError,
          });
        });
    },
    deleteProfile(profileType, profileId) {
      const {
        handleError,
        profileSettings: {
          [profileType]: {
            i18n,
            graphQL: { deletion },
          },
        },
      } = this;
      const profile = this.profileTypes[profileType].profiles.find(({ id }) => id === profileId);

      this.resetErrors(profileType);

      this.$apollo
        .mutate({
          mutation: deletion.mutation,
          variables: {
            input: {
              id: profileId,
            },
          },
          update(store, { data = {} }) {
            const errors = data[`${profileType}Delete`]?.errors ?? [];

            if (errors.length === 0) {
              cacheUtils.removeProfile({
                profile,
                store,
              });
            } else {
              handleError({
                message: i18n.errorMessages.deletionBackendError,
                details: errors,
              });
            }
          },
          optimisticResponse: deletion.optimisticResponse,
        })
        .catch((error) => {
          this.handleError({
            profileType,
            exception: error,
            message: i18n.errorMessages.deletionNetworkError,
          });
        });
    },
  },
  profilesPerPage: 10,
  i18n: {
    heading: s__('DastProfiles|DAST profile library'),
    newProfileDropdownLabel: __('New'),
    subHeading: s__(
      'DastProfiles|Save commonly used configurations for target sites and scan specifications as profiles. Use these with an on-demand scan.',
    ),
  },
};
</script>

<template>
  <section>
    <dast-failed-site-validations :full-path="projectFullPath" />
    <header>
      <div class="gl-display-flex gl-align-items-center gl-pt-6 gl-pb-4">
        <h2 class="my-0">
          {{ $options.i18n.heading }}
        </h2>
        <gl-disclosure-dropdown
          class="gl-ml-auto"
          placement="right"
          variant="confirm"
          :toggle-text="$options.i18n.newProfileDropdownLabel"
          :items="newProfileDisclosureItems"
        />
      </div>
      <p>
        {{ $options.i18n.subHeading }}
      </p>
    </header>

    <gl-tabs v-model="tabIndex">
      <gl-tab v-for="(settings, profileType) in profileSettings" :key="profileType">
        <template #title>
          <span>{{ settings.i18n.name }}</span>
        </template>

        <component
          :is="profileSettings[profileType].component"
          :data-testid="`${profileType}List`"
          :error-message="profileTypes[profileType].errorMessage"
          :error-details="profileTypes[profileType].errorDetails"
          :no-profiles-message="settings.i18n.noProfilesMessage"
          :has-more-profiles-to-load="hasMoreProfiles(profileType)"
          :is-loading="isLoadingProfiles(profileType)"
          :profiles-per-page="$options.profilesPerPage"
          :profiles="profileTypes[profileType].profiles"
          :table-label="settings.i18n.name"
          :fields="settings.tableFields"
          :full-path="projectFullPath"
          @load-more-profiles="fetchMoreProfiles(profileType)"
          @delete-profile="deleteProfile(profileType, $event)"
        />
      </gl-tab>
    </gl-tabs>
  </section>
</template>
