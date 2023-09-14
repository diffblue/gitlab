<script>
import { GlButton, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { s__ } from '~/locale';

export default {
  i18n: {
    buttonText: s__("ScanResultPolicy|Don't show me this again"),
  },
  components: {
    GlButton,
    GlLink,
    GlPopover,
    GlSprintf,
    UserCalloutDismisser,
  },
  props: {
    description: {
      type: String,
      required: true,
    },
    featureName: {
      type: String,
      required: true,
    },
    id: {
      type: String,
      required: true,
    },
    link: {
      type: String,
      required: false,
      default: '',
    },
    showPopover: {
      type: Boolean,
      required: false,
      default: false,
    },
    title: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <user-callout-dismisser :feature-name="featureName">
      <template #default="{ dismiss, shouldShowCallout }">
        <gl-popover
          v-if="shouldShowCallout"
          :show="showPopover"
          :target="id"
          triggers="manual"
          boundary="viewport"
          placement="left"
          show-close-button
        >
          <template #title>{{ title }}</template>
          <slot>
            <gl-sprintf :message="description">
              <template #link="{ content }">
                <gl-link v-if="link" :href="link" :data-testid="id" target="_blank">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </slot>
          <gl-button class="gl-mt-3" size="small" @click="dismiss">
            {{ $options.i18n.buttonText }}
          </gl-button>
        </gl-popover>
      </template>
    </user-callout-dismisser>
  </div>
</template>
