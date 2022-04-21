export const parseDependencies = (dependencies) => {
  return dependencies
    .map((dependency) => {
      return dependency.name;
    })
    .join(', ');
};
