# Apocalypse

Apocalypse is a prototype Node.js server monitoring application that is fully event driven.

## Links

 * [Source](https://github.com/ariejan/apocalyse)
 * [Issues](https://github.com/ariejan/apocalypse/issues)

## Installation

Installing Apocalypse on a server is quite easy:

 1. Checkout the current project: `git clone git://github.com/ariejan/apocalypse.git`
 2. Create a `config.js`, use [`config.example.yml`][1] as an example.
 3. Install the all dependencies
   * `npm link` to install all required Node.js modules
   * `gem install foreman` to start all workers easily
 4. Make sure you have redis up-and-running
 5. Start all workers/apps with `foreman start`. This should start (by default):
   * Metrics API server on port 3001
   * Dashboard server on port 3000
   * CPU Analysis worker
   * Memory Analysis worker
   * Swap Analysis worker
   * Disk Usage Analysis worker
   * Redis Persistence worker

## Development

To add features or create bug fixes setup your local environment as described under installation.

### Testing locally

To simulate servers pushing metrics to your development environment you can use the pre-recorded metric in [`test/fixtures/metrics.json`][2]. To use this file, issue the following `wget` command from the root of the project:

    wget --post-file=test/fixtures/stats.json --header='Content-type:application/json' -O- http://localhost:3001/api/metrics/SERVER_ID

## Tests

Right. This is still a prototype, so no tests are available as yet. The plan is to write Jasmine tests using jasmine-node and refactor Apocalypse accordingly. 

_A pull request is very welcome!_

## Contributing

  1. Fork the repository
  2. Create a feature branch and do your thing
  3. When done, create a pull request on Github

## License

Apocalypse is developed by Ariejan de Vroom and the following awesome contributors:

  * Bram Wijnands (bramboo)

Apocalpyse will be licensed under the MIT license.

[1]: https://github.com/ariejan/apocalypse/blob/master/config.example.js
[2]: https://github.com/ariejan/apocalypse/blob/master/test/fixtures/stats.json
