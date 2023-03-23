<script>
import { fullLabelId } from '~/boards/boards_util';
import BoardFormFoss from '~/boards/components/board_form.vue';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';

import createEpicBoardMutation from '../graphql/epic_board_create.mutation.graphql';
import destroyEpicBoardMutation from '../graphql/epic_board_destroy.mutation.graphql';
import updateEpicBoardMutation from '../graphql/epic_board_update.mutation.graphql';

// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
// eslint-disable-next-line @gitlab/no-runtime-template-compiler
export default {
  extends: BoardFormFoss,
  inject: ['isIssueBoard', 'isEpicBoard'],
  computed: {
    currentEpicBoardMutation() {
      return this.board.id ? updateEpicBoardMutation : createEpicBoardMutation;
    },
    issueBoardScopeMutationVariables() {
      return {
        weight: this.board.weight,
        assigneeId: this.board.assignee?.id
          ? convertToGraphQLId(TYPENAME_USER, this.board.assignee.id)
          : null,
        milestoneId: this.board.milestone?.id || null,
        iterationId: this.board.iteration?.id || null,
        iterationCadenceId: this.board.iterationCadenceId || null,
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
    async createOrUpdateBoard() {
      const response = await this.$apollo.mutate({
        mutation: this.isEpicBoard ? this.currentEpicBoardMutation : this.currentMutation,
        variables: { input: this.mutationVariables },
      });

      if (!this.board.id) {
        return this.isEpicBoard
          ? response.data.epicBoardCreate.epicBoard
          : response.data.createBoard.board;
      }

      return this.isEpicBoard
        ? response.data.epicBoardUpdate.epicBoard
        : response.data.updateBoard.board;
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
