<script>
// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
/* eslint-disable @gitlab/no-runtime-template-compiler */
import { mapGetters } from 'vuex';
import { fullLabelId } from '~/boards/boards_util';
import BoardFormFoss from '~/boards/components/board_form.vue';
import { TYPE_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';

import createEpicBoardMutation from '../graphql/epic_board_create.mutation.graphql';
import destroyEpicBoardMutation from '../graphql/epic_board_destroy.mutation.graphql';
import updateEpicBoardMutation from '../graphql/epic_board_update.mutation.graphql';

export default {
  extends: BoardFormFoss,
  computed: {
    ...mapGetters(['isEpicBoard']),
    currentEpicBoardMutation() {
      return this.board.id ? updateEpicBoardMutation : createEpicBoardMutation;
    },
    issueBoardScopeMutationVariables() {
      return {
        weight: this.board.weight,
        assigneeId: this.board.assignee?.id
          ? convertToGraphQLId(TYPE_USER, this.board.assignee.id)
          : null,
        milestoneId: this.board.milestone?.id || null,
        iterationId: this.board.iteration?.id || null,
      };
    },
    boardScopeMutationVariables() {
      return {
        labelIds: this.board.labels.map(fullLabelId),
        ...(this.isIssueBoard && this.issueBoardScopeMutationVariables),
      };
    },
    mutationVariables() {
      return {
        ...this.baseMutationVariables,
        ...(this.scopedIssueBoardFeatureEnabled || this.isEpicBoard
          ? this.boardScopeMutationVariables
          : {}),
      };
    },
  },
  methods: {
    epicBoardCreateResponse(data) {
      return data.epicBoardCreate.epicBoard.webPath;
    },
    epicBoardUpdateResponse(data) {
      return data.epicBoardUpdate.epicBoard.webPath;
    },
    async createOrUpdateBoard() {
      const response = await this.$apollo.mutate({
        mutation: this.isEpicBoard ? this.currentEpicBoardMutation : this.currentMutation,
        variables: { input: this.mutationVariables },
      });

      if (!this.board.id) {
        return this.isEpicBoard
          ? this.epicBoardCreateResponse(response.data)
          : this.boardCreateResponse(response.data);
      }

      return this.isEpicBoard
        ? this.epicBoardUpdateResponse(response.data)
        : this.boardUpdateResponse(response.data);
    },
    async deleteBoard() {
      await this.$apollo.mutate({
        mutation: this.isEpicBoard ? destroyEpicBoardMutation : this.deleteMutation,
        variables: {
          id: this.board.id,
        },
      });
    },
  },
};
</script>
