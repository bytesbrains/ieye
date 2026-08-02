// Public repository links. iEye is open source (MIT) — built in the open at
// bytesbrains/ieye. Firebase-free so it's safe in the main landing bundle.

export const GITHUB_REPO = "https://github.com/bytesbrains/ieye";

// Direct, version-stable download URLs for the freely-distributable builds. The
// Release workflow uploads these exact (version-less) asset names and marks the
// release `latest`, so these links always point at the newest published build.
// (They 404 until the first release is published.)
export const APP_DOWNLOADS = {
  Windows: `${GITHUB_REPO}/releases/latest/download/ieye-windows-x64.zip`,
  Linux: `${GITHUB_REPO}/releases/latest/download/ieye-linux-x64.tar.gz`,
  Android: `${GITHUB_REPO}/releases/latest/download/ieye-android.apk`,
} as const;

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
