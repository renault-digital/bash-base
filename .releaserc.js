module.exports = {
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github",
    "@semantic-release/git",
    ["@semantic-release/exec", {
      "prepareCmd": "docker build -t renaultdigital/bash-base . && npm run livedoc"
    }],
    ["semantic-release-docker", {
      "name": "renaultdigital/bash-base"
    }]
  ]
}
