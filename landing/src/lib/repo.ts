// Public repository links. iEye is open source (MIT) — built in the open at
// bytesbrains/ieye. Firebase-free so it's safe in the main landing bundle.

export const GITHUB_REPO = "https://github.com/bytesbrains/ieye";

export const REPO_LINKS = {
  repo: GITHUB_REPO,
  discussions: `${GITHUB_REPO}/discussions`,
  issues: `${GITHUB_REPO}/issues`,
  // GitHub's built-in "ways to contribute" page — surfaces good-first issues.
  goodFirstIssues: `${GITHUB_REPO}/contribute`,
  pulls: `${GITHUB_REPO}/pulls`,
  contributing: `${GITHUB_REPO}/blob/HEAD/CONTRIBUTING.md`,
  codeOfConduct: `${GITHUB_REPO}/blob/HEAD/CODE_OF_CONDUCT.md`,
} as const;
