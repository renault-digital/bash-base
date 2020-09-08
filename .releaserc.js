module.exports = {
  "plugins": [
    ["@semantic-release/commit-analyzer", {
        // https://github.com/semantic-release/commit-analyzer#releaserules
        releaseRules: [
          { scope: 'no-release', release: false },
          { breaking: true, release: 'major' },
          { type: 'feat', release: 'minor' },
          { type: 'perf', release: 'minor' },
          { type: 'refactor', release: 'minor' },
          { type: '*', release: 'patch' },
        ],
    }],
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    ["@semantic-release/exec", {
      "prepareCmd": "docker build -t renaultdigital/bash-base . && npm run livedoc"
    }],
    ["@semantic-release/git", {
      "assets": ['CHANGELOG.md', 'package.json', 'package-lock.json', 'npm-shrinkwrap.json', 'src', 'docs', 'man'],
      "message": "chore(release): ${nextRelease.version} [skip ci]"
    }],
    "@semantic-release/github",
    ["semantic-release-docker", {
      "name": "renaultdigital/bash-base"
    }]
  ]
}
