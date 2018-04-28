# Magic OpenAPI


## Overview

Magic OpenAPI is a tool to auto-generate API definition(ERB) for [Magic
Modules](https://github.com/huaweicloud/magic-modules)


### Supported Services

All the necessary data for a service to compile is under the `services/` folder.
For simplicity (yet not a requirement) the folder name is the actual service
name you will use in the `-s` parameter later on.

To see the full service list visit the [`services`](services/) folder.


## (One Time) Setup

Magic OpenAPI requires:

- git (so you can checkout the code)
- Ruby 2.0 or higher
- Bundler gem

### Installing bundler

As you have Ruby installed all you need is Bundler. To install it, run:

    gem install bundler

### Dependencies install

Now that we have Bundler installed, go to the root folder where you checked out
the Magic Modules code and run:

    bundle install

We are now ready to compile a service api!


## Compiling api

### Compiling a single service api

Compiling a service api is as easy as:

    bundle exec compiler -s <service> -o <folder>

For example, to compile Compute service, you invoke:

    bundle exec compiler -s services/compute -o /output/compute

And the generated api yaml should be written to `/output/compute`
