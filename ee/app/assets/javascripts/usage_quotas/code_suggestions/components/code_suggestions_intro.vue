<script>
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import {
  codeSuggestionsLearnMoreLink,
  salesLink,
} from 'ee/usage_quotas/code_suggestions/constants';
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';

export default {
  name: 'CodeSuggestionsIntro',
  helpLinks: {
    codeSuggestionsLearnMoreLink,
    salesLink,
  },
  i18n: {
    contactSales: __('Contact sales'),
    description: s__(
      `CodeSuggestions|Enhance your coding experience with intelligent recommendations. %{linkStart}Code Suggestions%{linkEnd} uses generative AI to suggest code while you're developing.`,
    ),
    title: s__('CodeSuggestions|Introducing the Code&nbsp;Suggestions add&#8209;on'),
  },
  directives: {
    SafeHtml,
  },
  components: {
    HandRaiseLeadButton,
    GlEmptyState,
    GlLink,
    GlSprintf,
  },
  apolloProvider,
  inject: ['createHandRaiseLeadPath'],
};
</script>
<template>
  <gl-empty-state
    :primary-button-text="$options.i18n.contactSales"
    :primary-button-link="$options.helpLinks.salesLink"
    class="gl-max-w-48"
  >
    <template #title>
      <h1
        v-safe-html="$options.i18n.title"
        class="gl-font-size-h-display gl-line-height-36 h4"
      ></h1>
    </template>
    <template #description>
      <gl-sprintf :message="$options.i18n.description">
        <template #link="{ content }">
          <gl-link :href="$options.helpLinks.codeSuggestionsLearnMoreLink" target="_blank">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
    <template #actions>
      <hand-raise-lead-button v-if="createHandRaiseLeadPath" />
    </template>
  </gl-empty-state>
</template>
