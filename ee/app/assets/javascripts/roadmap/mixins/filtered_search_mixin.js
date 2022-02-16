import { GlFilteredSearchToken } from '@gitlab/ui';
import { orderBy } from 'lodash';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

import {
  OPERATOR_IS_ONLY,
  OPERATOR_IS_NOT,
  OPERATOR_IS,
  OPERATOR_IS_AND_IS_NOT,
  DEFAULT_MILESTONE_UPCOMING,
  DEFAULT_MILESTONE_STARTED,
} from '~/vue_shared/components/filtered_search_bar/constants';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import EmojiToken from '~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import EpicToken from 'ee/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';

export default {
  inject: ['groupFullPath', 'groupMilestonesPath', 'listEpicsPath'],
  computed: {
    urlParams() {
      const {
        search,
        authorUsername,
        labelName,
        milestoneTitle,
        confidential,
        myReactionEmoji,
        epicIid,
        'not[authorUsername]': notAuthorUsername,
        'not[myReactionEmoji]': notMyReactionEmoji,
        'not[labelName]': notLabelName,
      } = this.filterParams || {};

      return {
        state: this.currentState || this.epicsState,
        page: this.currentPage,
        sort: this.sortedBy,
        prev: this.prevPageCursor || undefined,
        next: this.nextPageCursor || undefined,
        layout: this.presetType || undefined,
        timeframe_range_type: this.timeframeRangeType || undefined,
        author_username: authorUsername,
        'label_name[]': labelName,
        milestone_title: milestoneTitle,
        confidential,
        my_reaction_emoji: myReactionEmoji,
        epic_iid: epicIid,
        search,
        'not[author_username]': notAuthorUsername,
        'not[my_reaction_emoji]': notMyReactionEmoji,
        'not[label_name][]': notLabelName,
        progress: this.progressTracking,
        show_progress: this.isProgressTrackingActive,
        show_milestones: this.isShowingMilestones,
        milestones_type: this.milestonesType,
      };
    },
  },
  methods: {
    getFilteredSearchTokens({ supportsEpic = true } = {}) {
      let preloadedAuthors = [];

      if (gon.current_user_id) {
        preloadedAuthors = [
          {
            id: gon.current_user_id,
            name: gon.current_user_fullname,
            username: gon.current_username,
            avatar_url: gon.current_user_avatar_url,
          },
        ];
      }

      const tokens = [
        {
          type: 'author_username',
          icon: 'user',
          title: __('Author'),
          unique: true,
          symbol: '@',
          token: AuthorToken,
          operators: OPERATOR_IS_AND_IS_NOT,
          recentSuggestionsStorageKey: `${this.groupFullPath}-epics-recent-tokens-author_username`,
          fetchAuthors: Api.users.bind(Api),
          defaultAuthors: [],
          preloadedAuthors,
        },
        {
          type: 'label_name',
          icon: 'labels',
          title: __('Label'),
          unique: false,
          symbol: '~',
          token: LabelToken,
          operators: OPERATOR_IS_AND_IS_NOT,
          recentSuggestionsStorageKey: `${this.groupFullPath}-epics-recent-tokens-label_name`,
          fetchLabels: (search = '') => {
            const params = {
              only_group_labels: true,
              include_ancestor_groups: true,
              include_descendant_groups: true,
            };

            if (search) {
              params.search = search;
            }

            return Api.groupLabels(encodeURIComponent(this.groupFullPath), {
              params,
            });
          },
        },
        {
          type: 'milestone_title',
          icon: 'clock',
          title: __('Milestone'),
          unique: true,
          symbol: '%',
          token: MilestoneToken,
          operators: OPERATOR_IS_ONLY,
          defaultMilestones: [DEFAULT_MILESTONE_UPCOMING, DEFAULT_MILESTONE_STARTED],
          fetchMilestones: (search = '') => {
            return axios.get(this.groupMilestonesPath).then(({ data }) => {
              // TODO: Remove below condition check once either of the following is supported.
              // a) Milestones Private API supports search param.
              // b) Milestones Public API supports including child projects' milestones.
              if (search) {
                return {
                  data: data.filter((m) => m.title.toLowerCase().includes(search.toLowerCase())),
                };
              }
              return { data };
            });
          },
        },
        {
          type: 'confidential',
          icon: 'eye-slash',
          title: __('Confidential'),
          unique: true,
          token: GlFilteredSearchToken,
          operators: OPERATOR_IS_ONLY,
          options: [
            { icon: 'eye-slash', value: true, title: __('Yes') },
            { icon: 'eye', value: false, title: __('No') },
          ],
        },
      ];

      if (supportsEpic) {
        tokens.push({
          type: 'epic_iid',
          icon: 'epic',
          title: __('Epic'),
          unique: true,
          idProperty: 'iid',
          useIdValue: true,
          symbol: '&',
          token: EpicToken,
          operators: OPERATOR_IS_ONLY,
          recentSuggestionsStorageKey: `${this.groupFullPath}-epics-recent-tokens-epic_iid`,
          fullPath: this.groupFullPath,
        });
      }

      if (gon.current_user_id) {
        // Appending to tokens only when logged-in
        tokens.push({
          type: 'my_reaction_emoji',
          icon: 'thumb-up',
          title: __('My-Reaction'),
          unique: true,
          token: EmojiToken,
          operators: OPERATOR_IS_AND_IS_NOT,
          fetchEmojis: (search = '') => {
            return axios
              .get(`${gon.relative_url_root || ''}/-/autocomplete/award_emojis`)
              .then(({ data }) => {
                if (search) {
                  return {
                    data: data.filter((e) => e.name.toLowerCase().includes(search.toLowerCase())),
                  };
                }
                return { data };
              });
          },
        });
      }

      return orderBy(tokens, ['title']);
    },
    getFilteredSearchValue() {
      const {
        authorUsername,
        labelName,
        milestoneTitle,
        confidential,
        myReactionEmoji,
        search,
        epicIid,
        'not[authorUsername]': notAuthorUsername,
        'not[myReactionEmoji]': notMyReactionEmoji,
        'not[labelName]': notLabelName,
      } = this.filterParams || {};
      const filteredSearchValue = [];

      if (authorUsername) {
        filteredSearchValue.push({
          type: 'author_username',
          value: { data: authorUsername, operator: OPERATOR_IS },
        });
      }

      if (notAuthorUsername) {
        filteredSearchValue.push({
          type: 'author_username',
          value: { data: notAuthorUsername, operator: OPERATOR_IS_NOT },
        });
      }

      if (labelName?.length && Array.isArray(labelName)) {
        filteredSearchValue.push(
          ...labelName.map((label) => ({
            type: 'label_name',
            value: { data: label, operator: OPERATOR_IS },
          })),
        );
      }
      if (notLabelName?.length) {
        filteredSearchValue.push(
          ...notLabelName.map((label) => ({
            type: 'label_name',
            value: { data: label, operator: OPERATOR_IS_NOT },
          })),
        );
      }

      if (milestoneTitle) {
        filteredSearchValue.push({
          type: 'milestone_title',
          value: { data: milestoneTitle },
        });
      }

      if (confidential !== undefined) {
        filteredSearchValue.push({
          type: 'confidential',
          value: { data: confidential },
        });
      }

      if (myReactionEmoji) {
        filteredSearchValue.push({
          type: 'my_reaction_emoji',
          value: { data: myReactionEmoji, operator: OPERATOR_IS },
        });
      }
      if (notMyReactionEmoji) {
        filteredSearchValue.push({
          type: 'my_reaction_emoji',
          value: { data: notMyReactionEmoji, operator: OPERATOR_IS_NOT },
        });
      }

      if (epicIid) {
        filteredSearchValue.push({
          type: 'epic_iid',
          value: { data: epicIid },
        });
      }

      if (search) {
        filteredSearchValue.push(search);
      }

      return filteredSearchValue;
    },
    getFilterParams(filters = []) {
      const filterParams = {};
      const labels = [];
      const notLabels = [];
      const plainText = [];

      filters.forEach((filter) => {
        switch (filter.type) {
          case 'author_username': {
            const key =
              filter.value.operator === OPERATOR_IS_NOT ? 'not[authorUsername]' : 'authorUsername';
            filterParams[key] = filter.value.data;
            break;
          }
          case 'label_name':
            if (filter.value.operator === OPERATOR_IS_NOT) {
              notLabels.push(filter.value.data);
            } else {
              labels.push(filter.value.data);
            }
            break;
          case 'milestone_title':
            filterParams.milestoneTitle = filter.value.data;
            break;
          case 'confidential':
            filterParams.confidential = filter.value.data;
            break;
          case 'my_reaction_emoji': {
            const key =
              filter.value.operator === OPERATOR_IS_NOT
                ? 'not[myReactionEmoji]'
                : 'myReactionEmoji';

            filterParams[key] = filter.value.data;
            break;
          }
          case 'epic_iid':
            filterParams.epicIid = filter.value.data;
            break;
          case 'filtered-search-term':
            if (filter.value.data) plainText.push(filter.value.data);
            break;
          default:
            break;
        }
      });

      if (labels.length) {
        filterParams.labelName = labels;
      }

      if (notLabels.length) {
        filterParams[`not[labelName]`] = notLabels;
      }

      if (plainText.length) {
        filterParams.search = plainText.join(' ');
      }

      return filterParams;
    },
  },
};
