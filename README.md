This is a fairly minimal, unobtrusive request routing library, part of the
Clutterbuck Web Application Construction Kit.


# Installation

It's a gem:

    gem install clutterbuck-router

There's also the wonders of [the Gemfile](http://bundler.io):

    gem 'clutterbuck-router'

If you're the sturdy type that likes to run from git:

    rake install

Or, if you've eschewed the convenience of Rubygems entirely, then you
presumably know what to do already.


# Usage

Load the code:

    require 'clutterbuck-router'

Then include {Clutterbuck::Router} in any class you wish to be a Rack
application using the Clutterbuck router:

    class ExampleApp
      include Clutterbuck::Router
    end

Now, you define the routes you wish the application to respond to:

    class ExampleApp
      include Clutterbuck::Router

      get '/' do
        [200, [["Content-Type", "text/plain"]], ["Ohai!"]]
      end

      post %r{^/mail/([^/]+)$} do |path_opt|
        [200, [["Content-Type", "text/plain"]],
         ["You posted #{env['rack.input'].read} to #{path_opt}"]
        ]
      end
    end

The above example pretty much demonstrates all the features that
{Clutterbuck::Router} provides.  You define routes by means of methods named
after the HTTP verb to respond to, and the path is either a string or a
regex.  If you specify a string, then the path provided must match *exactly*
the request path.  If you specify a regex, then the first route which
matches the request path and method gets run, with any captured
subexpressions (ie "the bits in the parentheses") get passed as arguments to
the block.

The `env` method returns the request's Rack environment; apart from that,
you're on your own as far as interacting with Rack itself -- you have to
parse out the query params and request body, and return your own response
array in the Rack-compatible format.  If that all sounds like too much work,
you might want to look at `clutterbuck-request` and/or
`clutterbuck-response` to get syntactic sugar to help with those parts of
your app.

Once your app is crafted to your liking, you can put it into a `config.ru`:

    require 'example_app'

    use ExampleApp

Fire that up via `rackup`, and you're off and running.


# Contributing

Bug reports should be sent to the [Github issue
tracker](https://github.com/mpalmer/clutterbuck-router/issues), or
[e-mailed](mailto:theshed+clutterbuck@hezmatt.org).  Patches can be sent as a
Github pull request, or [e-mailed](mailto:theshed+clutterbuck@hezmatt.org).


# Licence

Unless otherwise stated, everything in this repo is covered by the following
copyright notice:

    Copyright (C) 2015  Matt Palmer <matt@hezmatt.org>

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
