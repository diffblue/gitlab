import activateNextStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/activate_next_step.mutation.graphql';
import updateStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/update_active_step.mutation.graphql';
import activeStepQuery from 'ee/vue_shared/purchase_flow/graphql/queries/active_step.query.graphql';
import stepListQuery from 'ee/vue_shared/purchase_flow/graphql/queries/step_list.query.graphql';
import { STEPS } from '../mock_data';
import { createMockApolloProvider } from '../spec_helper';

describe('ee/vue_shared/purchase_flow/graphql/resolvers', () => {
  let mockApolloClient;

  describe('Query', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider(STEPS, 0);
      mockApolloClient = mockApollo.clients.defaultClient;
    });

    describe('stepListQuery', () => {
      it('stores the stepList', async () => {
        const queryResult = await mockApolloClient.query({ query: stepListQuery });
        expect(queryResult.data.stepList).toMatchObject(
          STEPS.map(({ id }) => {
            return { id };
          }),
        );
      });
    });

    describe('activeStepQuery', () => {
      it('stores the activeStep', async () => {
        const queryResult = await mockApolloClient.query({ query: activeStepQuery });
        expect(queryResult.data.activeStep).toMatchObject({ id: STEPS[0].id });
      });
    });
  });

  describe('Mutation', () => {
    describe('updateActiveStep', () => {
      beforeEach(() => {
        const mockApollo = createMockApolloProvider(STEPS, 0);
        mockApolloClient = mockApollo.clients.defaultClient;
      });

      it('updates the active step', async () => {
        await mockApolloClient.mutate({
          mutation: updateStepMutation,
          variables: { id: STEPS[1].id },
        });
        const queryResult = await mockApolloClient.query({ query: activeStepQuery });
        expect(queryResult.data.activeStep).toMatchObject({ id: STEPS[1].id });
      });

      it('throws an error when STEP is not present', async () => {
        const id = 'does not exist';
        await mockApolloClient
          .mutate({
            mutation: updateStepMutation,
            variables: { id },
          })
          .catch((e) => {
            expect(e instanceof Error).toBe(true);
          });
      });

      it('throws an error when cache is not initiated properly', async () => {
        mockApolloClient.clearStore();
        await mockApolloClient
          .mutate({
            mutation: updateStepMutation,
            variables: { id: STEPS[1].id },
          })
          .catch((e) => {
            expect(e instanceof Error).toBe(true);
          });
      });
    });

    describe('activateNextStep', () => {
      it('updates the active step to the next', async () => {
        const mockApollo = createMockApolloProvider(STEPS, 0);
        mockApolloClient = mockApollo.clients.defaultClient;
        await mockApolloClient.mutate({
          mutation: activateNextStepMutation,
        });
        const queryResult = await mockApolloClient.query({ query: activeStepQuery });
        expect(queryResult.data.activeStep).toMatchObject({ id: STEPS[1].id });
      });

      it('throws an error when out of bounds', async () => {
        const mockApollo = createMockApolloProvider(STEPS, 2);
        mockApolloClient = mockApollo.clients.defaultClient;

        await mockApolloClient
          .mutate({
            mutation: activateNextStepMutation,
          })
          .catch((e) => {
            expect(e instanceof Error).toBe(true);
          });
      });

      it('throws an error when cache is not initiated properly', async () => {
        mockApolloClient.clearStore();
        await mockApolloClient
          .mutate({
            mutation: activateNextStepMutation,
          })
          .catch((e) => {
            expect(e instanceof Error).toBe(true);
          });
      });
    });
  });
});
