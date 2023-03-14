<script>
import { GlFormGroup, GlFormInput, GlLink } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { s__, __ } from '~/locale';
import { VALIDATION_FIELD_KEYS, REVERIFICATION_MORE_INFO, BACKFILL_MORE_INFO } from '../constants';
import { validateCapacity } from '../validations';

export default {
  name: 'GeoSiteFormCapacities',
  i18n: {
    repositoryCapacityFieldLabel: s__('Geo|Repository synchronization concurrency limit'),
    fileCapacityFieldLabel: s__('Geo|File synchronization concurrency limit'),
    containerRepositoryCapacityFieldLabel: s__(
      'Geo|Container repositories synchronization concurrency limit',
    ),
    verificationCapacityFieldLabel: s__('Geo|Verification concurrency limit'),
    reverificationIntervalFieldLabel: s__('Geo|Re-verification interval'),
    reverificationIntervalFieldDescription: s__('Geo|Minimum interval in days'),
    primarySiteSectionDescription: s__('Geo|Set verification limit and frequency.'),
    secondarySiteSectionDescription: s__(
      'Geo|Limit the number of concurrent operations this secondary site can run in the background.',
    ),
    tuningSettings: s__('Geo|Tuning settings'),
    learnMore: __('Learn more'),
  },
  components: {
    GlFormGroup,
    GlFormInput,
    GlLink,
  },
  props: {
    siteData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      formGroups: [
        {
          id: 'site-repository-capacity-field',
          label: this.$options.i18n.repositoryCapacityFieldLabel,
          key: VALIDATION_FIELD_KEYS.REPOS_MAX_CAPACITY,
          conditional: 'secondary',
        },
        {
          id: 'site-file-capacity-field',
          label: this.$options.i18n.fileCapacityFieldLabel,
          key: VALIDATION_FIELD_KEYS.FILES_MAX_CAPACITY,
          conditional: 'secondary',
        },
        {
          id: 'site-container-repository-capacity-field',
          label: this.$options.i18n.containerRepositoryCapacityFieldLabel,
          key: VALIDATION_FIELD_KEYS.CONTAINER_REPOSITORIES_MAX_CAPACITY,
          conditional: 'secondary',
        },
        {
          id: 'site-verification-capacity-field',
          label: this.$options.i18n.verificationCapacityFieldLabel,
          key: VALIDATION_FIELD_KEYS.VERIFICATION_MAX_CAPACITY,
        },
        {
          id: 'site-reverification-interval-field',
          label: this.$options.i18n.reverificationIntervalFieldLabel,
          description: this.$options.i18n.reverificationIntervalFieldDescription,
          key: VALIDATION_FIELD_KEYS.MINIMUM_REVERIFICATION_INTERVAL,
          conditional: 'primary',
        },
      ],
    };
  },
  computed: {
    ...mapState(['formErrors']),
    visibleFormGroups() {
      return this.formGroups.filter((group) => {
        if (group.conditional) {
          return this.siteData.primary
            ? group.conditional === 'primary'
            : group.conditional === 'secondary';
        }
        return true;
      });
    },
    sectionDescription() {
      return this.siteData.primary
        ? this.$options.i18n.primarySiteSectionDescription
        : this.$options.i18n.secondarySiteSectionDescription;
    },
    sectionLink() {
      return this.siteData.primary ? REVERIFICATION_MORE_INFO : BACKFILL_MORE_INFO;
    },
  },
  methods: {
    ...mapActions(['setError']),
    checkCapacity(formGroup) {
      this.setError({
        key: formGroup.key,
        error: validateCapacity({ data: this.siteData[formGroup.key], label: formGroup.label }),
      });
    },
  },
};
</script>

<template>
  <div>
    <h2 class="gl-font-size-h2 gl-my-5">{{ $options.i18n.tuningSettings }}</h2>
    <p class="gl-mb-5">
      {{ sectionDescription }}
      <gl-link :href="sectionLink" target="_blank">{{ $options.i18n.learnMore }}</gl-link>
    </p>
    <gl-form-group
      v-for="formGroup in visibleFormGroups"
      :key="formGroup.id"
      :label="formGroup.label"
      :label-for="formGroup.id"
      :description="formGroup.description"
      :state="Boolean(formErrors[formGroup.key])"
      :invalid-feedback="formErrors[formGroup.key]"
    >
      <!-- eslint-disable vue/no-mutating-props -->
      <gl-form-input
        :id="formGroup.id"
        v-model="siteData[formGroup.key]"
        :class="{ 'is-invalid': Boolean(formErrors[formGroup.key]) }"
        class="col-sm-3"
        type="number"
        @update="checkCapacity(formGroup)"
      />
      <!-- eslint-enable vue/no-mutating-props -->
    </gl-form-group>
  </div>
</template>
