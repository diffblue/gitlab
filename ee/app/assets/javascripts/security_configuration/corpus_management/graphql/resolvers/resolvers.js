import produce from 'immer';
import { publishPackage } from '~/api/packages_api';
import axios from '~/lib/utils/axios_utils';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PACKAGES_PACKAGE } from '~/graphql_shared/constants';
import getUploadState from '../queries/get_upload_state.query.graphql';
import updateProgress from '../mutations/update_progress.mutation.graphql';
import uploadComplete from '../mutations/upload_complete.mutation.graphql';
import uploadError from '../mutations/upload_error.mutation.graphql';
import corpusCreate from '../mutations/corpus_create.mutation.graphql';
import { parseNameError, parseFileError } from './utils';

export default {
  Query: {
    uploadState() {
      return {
        isUploading: false,
        progress: 0,
        cancelSource: null,
        uploadedPackageId: null,
        errors: {
          name: '',
          file: '',
          /* eslint-disable-next-line @gitlab/require-i18n-strings */
          __typename: 'Errors',
        },
        __typename: 'UploadState',
      };
    },
  },
  Mutation: {
    addCorpus: (_, { projectPath, packageId }, { cache, client }) => {
      const sourceData = cache.readQuery({
        query: getUploadState,
        variables: { projectPath },
      });

      const data = produce(sourceData, (draftState) => {
        draftState.uploadState.isUploading = false;
        draftState.uploadState.progress = 0;
      });

      cache.writeQuery({ query: getUploadState, data, variables: { projectPath } });

      client.mutate({
        mutation: corpusCreate,
        variables: {
          input: {
            fullPath: projectPath,
            packageId: convertToGraphQLId(TYPENAME_PACKAGES_PACKAGE, packageId),
          },
        },
      });
    },
    uploadCorpus: (_, { projectPath, name, files }, { cache, client }) => {
      const onUploadProgress = (e) => {
        client.mutate({
          mutation: updateProgress,
          variables: { projectPath, progress: Math.round((e.loaded / e.total) * 100) },
        });
      };

      const { CancelToken } = axios;
      const source = CancelToken.source();

      const sourceData = cache.readQuery({
        query: getUploadState,
        variables: { projectPath },
      });

      const targetData = produce(sourceData, (draftState) => {
        const { uploadState } = draftState;
        uploadState.isUploading = true;
        uploadState.cancelSource = source;
        uploadState.errors.name = '';
        uploadState.errors.file = '';
      });

      cache.writeQuery({ query: getUploadState, data: targetData, variables: { projectPath } });

      publishPackage(
        { projectPath, name, version: '1.0.0', fileName: `artifacts.zip`, files },
        { status: 'hidden', select: 'package_file' },
        { onUploadProgress, cancelToken: source.token },
      )
        .then(({ data }) => {
          client.mutate({
            mutation: uploadComplete,
            variables: { projectPath, packageId: data.package_id },
          });
        })
        .catch((e) => {
          const { error } = e.response.data;
          client.mutate({
            mutation: uploadError,
            variables: { projectPath, error },
          });
        });
    },
    uploadError: (_, { projectPath, error }, { cache }) => {
      const sourceData = cache.readQuery({
        query: getUploadState,
        variables: { projectPath },
      });

      const data = produce(sourceData, (draftState) => {
        const { uploadState } = draftState;
        uploadState.isUploading = false;
        uploadState.progress = 0;
        uploadState.cancelSource = null;
        uploadState.errors.name = parseNameError(error);
        uploadState.errors.file = parseFileError(error);
      });

      cache.writeQuery({ query: getUploadState, data, variables: { projectPath } });
    },
    uploadComplete: (_, { projectPath, packageId }, { cache }) => {
      const sourceData = cache.readQuery({
        query: getUploadState,
        variables: { projectPath },
      });

      const data = produce(sourceData, (draftState) => {
        const { uploadState } = draftState;
        uploadState.isUploading = false;
        uploadState.cancelSource = null;
        uploadState.uploadedPackageId = packageId;
        uploadState.errors.name = '';
        uploadState.errors.file = '';
      });

      cache.writeQuery({ query: getUploadState, data, variables: { projectPath } });
    },
    updateProgress: (_, { projectPath, progress }, { cache }) => {
      const sourceData = cache.readQuery({
        query: getUploadState,
        variables: { projectPath },
      });

      const data = produce(sourceData, (draftState) => {
        const { uploadState } = draftState;
        uploadState.isUploading = true;
        uploadState.progress = progress;
        uploadState.errors.name = '';
        uploadState.errors.file = '';
      });

      cache.writeQuery({ query: getUploadState, data, variables: { projectPath } });
    },
    resetCorpus: (_, { projectPath }, { cache }) => {
      const sourceData = cache.readQuery({
        query: getUploadState,
        variables: { projectPath },
      });

      sourceData.uploadState.cancelSource?.cancel();

      const data = produce(sourceData, (draftState) => {
        const { uploadState } = draftState;
        uploadState.isUploading = false;
        uploadState.progress = 0;
        uploadState.cancelToken = null;
        uploadState.uploadedPackageId = null;
        uploadState.errors.name = '';
        uploadState.errors.file = '';
      });

      cache.writeQuery({ query: getUploadState, data, variables: { projectPath } });
    },
  },
};
