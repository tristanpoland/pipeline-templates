Pipeline Templates
==================

This repository collects up all that tribal wisdom we've gained
from building Concourse Pipelines for various different purposes.
Each template provides a base `ci/pipeline.yml` that structures the
pipeline, `ci/settings.yml` to override any parameters defined by the template, a set of scripts (in `ci/scripts/`) that are referenced
from the pipeline, and a `ci/repipe` utility for putting all the
pieces together into a functioning Concourse pipeline.

Setup is straightforward:

```
git clone https://github.com/starkandwayne/pipeline-templates
cd pipeline-templates
./setup boshrelease ~/bosh/my-new-boshrelease
```

Alternatively, you can initialize the pipeline from inside the
target repository:

```
cd code/my-docker-thing
~/code/pipeline-templates/setup docker/base
```
The first argument to `setup` is the template you want to use. Currently available templates:

* `docker/base`
* `go`
* `boshrelease`

Don't let the name fool you!  `./setup` can also be used to update
an existing templated pipeline `ci/` directory to pick up new
changes made to the templates.

Once you've set up your repository, you'll need to fill in your
`ci/settings.yml` file with any parameters the template required:

```
cd code/my-project
ci/repipe # Attempt to update the pipeline config,
          # spitting out errors for missing parameters
vi ci/settings.yml # fill in the missing parameters
ci/repipe # Deploy the pipeline config!
```

### Dependencies

The `ci/repipe` script uses [Spruce](https://github.com/geofffranks/spruce) to merge `ci/pipeline.yml` and your bespoke `ci/settings.yml`.

On MacOS/Homebrew:

```
brew install starkandwayne/cf/spruce
```

On Debian/Ubuntu:

```
wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | apt-key add -
echo "deb http://apt.starkandwayne.com stable main" | tee /etc/apt/sources.list.d/starkandwayne.list
apt-get update

apt-get install spruce
```


## And Now, The Templates!

### docker/base and docker/ext-tests

For building Docker images, with tests.  This template comes in
two flavors: `docker/base` (where the unit tests are inside the
Docker image) and `docker/ext-tests`, where the tests live outside
of the image.

![Docker Pipeline][docker-pipeline]

### go

Takes a Go software project repository, runs unit tests and
(when the manual `shipit` job is run) releases to Github.

![Go Project Pipeline][go-pipeline]

[docker-pipeline]:      https://raw.githubusercontent.com/starkandwayne/pipeline-templates/master/screenshots/docker.png
[boshrelease-pipeline]: https://raw.githubusercontent.com/starkandwayne/pipeline-templates/master/screenshots/boshrelease.png
[go-pipeline]:          https://raw.githubusercontent.com/starkandwayne/pipeline-templates/master/screenshots/go.png


### boshrelease

Tries to create a BOSH release from the repository, upload it to a
hosted BOSH-lite for viability testing, and (when the manual
`shipit` job is run) releasing it to Github with a tarball
artifact, and also uploading that release tarball to S3.

![BOSH Release Pipeline][boshrelease-pipeline]
