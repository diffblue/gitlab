import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/security_dashboard/store/modules/pipeline_jobs/actions';
import * as types from 'ee/security_dashboard/store/modules/pipeline_jobs/mutation_types';
import createState from 'ee/security_dashboard/store/modules/pipeline_jobs/state';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';

import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('pipeling jobs actions', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('setPipelineJobsPath', () => {
    const pipelineJobsPath = 123;

    it('should commit the SET_PIPELINE_JOBS_PATH mutation', async () => {
      await testAction(
        actions.setPipelineJobsPath,
        pipelineJobsPath,
        state,
        [
          {
            type: types.SET_PIPELINE_JOBS_PATH,
            payload: pipelineJobsPath,
          },
        ],
        [],
      );
    });
  });

  describe('setProjectId', () => {
    const projectId = 123;

    it('should commit the SET_PIPELINE_JOBS_PATH mutation', async () => {
      await testAction(
        actions.setProjectId,
        projectId,
        state,
        [
          {
            type: types.SET_PROJECT_ID,
            payload: projectId,
          },
        ],
        [],
      );
    });
  });

  describe('setPipelineId', () => {
    const pipelineId = 123;

    it('should commit the SET_PIPELINE_ID mutation', async () => {
      await testAction(
        actions.setPipelineId,
        pipelineId,
        state,
        [
          {
            type: types.SET_PIPELINE_ID,
            payload: pipelineId,
          },
        ],
        [],
      );
    });
  });

  describe('fetchPipelineJobs', () => {
    let mock;
    const jobs = [{}, {}];

    beforeEach(() => {
      state.pipelineJobsPath = `${TEST_HOST}/pipelines/jobs.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success with pipeline path', () => {
      beforeEach(() => {
        mock.onGet(state.pipelineJobsPath).replyOnce(HTTP_STATUS_OK, jobs);
      });

      it('should commit the request and success mutations', async () => {
        await testAction(
          actions.fetchPipelineJobs,
          {},
          state,
          [
            { type: types.REQUEST_PIPELINE_JOBS },
            {
              type: types.RECEIVE_PIPELINE_JOBS_SUCCESS,
              payload: jobs,
            },
          ],
          [],
        );
      });
    });

    describe('on success with pipeline id and project id', () => {
      beforeEach(() => {
        mock
          .onGet('/api/undefined/projects/123/pipelines/321/jobs')
          .replyOnce(HTTP_STATUS_OK, jobs);
      });

      it('should commit the request and success mutations', async () => {
        state.pipelineJobsPath = '';
        state.projectId = 123;
        state.pipelineId = 321;

        await testAction(
          actions.fetchPipelineJobs,
          {},
          state,
          [
            { type: types.REQUEST_PIPELINE_JOBS },
            {
              type: types.RECEIVE_PIPELINE_JOBS_SUCCESS,
              payload: jobs,
            },
          ],
          [],
        );
      });
    });

    describe('without pipelineJobsPath set', () => {
      beforeEach(() => {
        mock.onGet(state.pipelineJobsPath).replyOnce(HTTP_STATUS_OK, jobs);
      });

      it('should commit RECEIVE_PIPELINE_JOBS_ERROR mutation', async () => {
        state.pipelineJobsPath = '';

        await testAction(
          actions.fetchPipelineJobs,
          {},
          state,
          [
            {
              type: types.RECEIVE_PIPELINE_JOBS_ERROR,
            },
          ],
          [],
        );
      });
    });

    describe('without projectId or pipelineId set', () => {
      beforeEach(() => {
        mock.onGet(state.pipelineJobsPath).replyOnce(HTTP_STATUS_OK, jobs);
      });

      it('should commit RECEIVE_PIPELINE_JOBS_ERROR mutation', async () => {
        state.pipelineJobsPath = '';
        state.projectId = undefined;
        state.pipelineId = undefined;

        await testAction(
          actions.fetchPipelineJobs,
          {},
          state,
          [
            {
              type: types.RECEIVE_PIPELINE_JOBS_ERROR,
            },
          ],
          [],
        );
      });
    });

    describe('with server error', () => {
      beforeEach(() => {
        mock.onGet(state.pipelineJobsPath).replyOnce(HTTP_STATUS_NOT_FOUND);
      });

      it('should commit REQUEST_PIPELINE_JOBS and RECEIVE_PIPELINE_JOBS_ERROR mutation', async () => {
        await testAction(
          actions.fetchPipelineJobs,
          {},
          state,
          [
            { type: types.REQUEST_PIPELINE_JOBS },
            {
              type: types.RECEIVE_PIPELINE_JOBS_ERROR,
            },
          ],
          [],
        );
      });
    });
  });
});
