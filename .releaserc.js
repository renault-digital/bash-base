module.exports = {
  "plugins": [
    ["@semantic-release/commit-analyzer", {
        // https://github.com/semantic-release/commit-analyzer#releaserules
        releaseRules: [
          { scope: 'no-release', release: false },
          { breaking: true, release: 'major' },
          { type: 'feat', release: 'minor' },
          { type: 'perf', release: 'minor' },
          { type: '*', release: 'patch' },
        ],
    }],
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    ["@semantic-release/exec", {
      "prepareCmd": "npm run build && docker build -t renaultdigital/bash-base ."
    }],
    ["@semantic-release/git", {
      "assets": ['CHANGELOG.md', 'package.json', 'package-lock.json', 'npm-shrinkwrap.json', 'src', 'docs', 'man', 'bin'],
    }],
    "@semantic-release/github",
    ["@semantic-release/exec", {
      "publishCmd": [
        "docker tag renaultdigital/bash-base renaultdigital/bash-base:${nextRelease.version}",
        "docker push renaultdigital/bash-base:${nextRelease.version}",
        "docker push renaultdigital/bash-base"
      ].join(" && ")
    }]
  ]
}
