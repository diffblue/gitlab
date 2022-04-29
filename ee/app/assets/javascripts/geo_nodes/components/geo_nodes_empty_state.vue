<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import { GEO_INFO_URL } from '../constants';

export default {
  name: 'GeoNodesEmptyState',
  i18n: {
    learnMoreButtonText: s__('Geo|Learn more about Geo'),
  },
  components: {
    GlEmptyState,
  },
  inject: {
    geoNodesEmptyStateSvg: {
      default: '',
    },
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    showLearnMoreButton: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    primaryButtonLink() {
      return this.showLearnMoreButton ? GEO_INFO_URL : '';
    },
    primaryButtonText() {
      return this.showLearnMoreButton ? this.$options.i18n.learnMoreButtonText : '';
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="title"
    :svg-path="geoNodesEmptyStateSvg"
    :description="description"
    :primary-button-link="primaryButtonLink"
    :primary-button-text="primaryButtonText"
  />
</template>
