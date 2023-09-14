import axios from '~/lib/utils/axios_utils';

export const findTargetBranch = async (branch) => {
  const path = document.querySelector('.js-merge-request-new-compare')?.dataset
    .targetBranchFinderPath;

  if (!path) return null;

  const { data } = await axios.get(path, { params: { branch_name: branch } });

  return data.target_branch;
};
