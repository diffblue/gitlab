export const populateWorkspacesWithProjectNames = (workspaces, projects) => {
  return workspaces.map((workspace) => {
    const project = projects.find((p) => p.id === workspace.projectId);

    return {
      ...workspace,
      projectName: project?.nameWithNamespace || workspace.projectId,
    };
  });
};
