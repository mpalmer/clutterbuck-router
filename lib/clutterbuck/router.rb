require 'clutterbuck/router/route'

#:nodoc:
module Clutterbuck; end

# A minimal router for Rack-compatible web applications.
#
# Does request routing, and *only* request routing.  You specify
# routes as strings (exact match) or regexes, and then when the
# app gets a request, the appropriate route gets executed.
#
module Clutterbuck::Router
	#:nodoc:
	# Signals that the router got a 404.  Should never escape the app call.
	#
	class NotFoundError < StandardError; end

	#:nodoc:
	# Signals that the router got a 405.  Should never escape the app call.
	#
	class MethodNotAllowedError < StandardError; end

	# All of the methods to define the app's routing behaviour are defined
	# on the class, because that's where the config lives.  Instances of the
	# app class are created to handle requests.
	#
	module ClassMethods
		# Process a request from the app.
		#
		def call(env)
			self.new(env).call
		end

		# @!macro handler_args
		#   See {.add_handler} for all the gory details.
		#
		#   @param path [String, Regexp]
		#
		#   @param block [Proc]
		#
		#   @return void
		#

		# Define a handler for `GET <path>` and `HEAD <path>` requests.
		#
		# @macro handler_args
		#
		def get(path, &block)
			add_handler('GET', path, &block)
			add_handler('HEAD', path, &block)
		end

		# Define a handler for `PUT <path>` requests.
		#
		# @macro handler_args
		#
		def put(path, &block)
			add_handler('PUT', path, &block)
		end

		# Define a handler for `POST <path>` requests.
		#
		# @macro handler_args
		#
		def post(path, &block)
			add_handler('POST', path, &block)
		end

		# Define a handler for `DELETE <path>` requests.
		#
		# @macro handler_args
		#
		def delete(path, &block)
			add_handler('DELETE', path, &block)
		end

		# Define a handler for `PATCH <path>` requests.
		#
		# @macro handler_args
		#
		def patch(path, &block)
			add_handler('PATCH', path, &block)
		end

		# Define a handler for an arbitrary HTTP method and path.
		#
		# If more than one handler for a given `verb` and `path` match a URL,
		# then the first handler defined will be called.
		#
		# If no handler matches given `path`, then `404 Not Found` will be
		# returned.  If a handler exists for `path`, but does not support the
		# method of the request, then `405 Method Not Allowed` will be
		# returned to the client.
		#
		# The return value of the `block` can be one of a number of different
		# things.  If you set the `Content-Type` response header (by calling
		# `set_header 'Content-Type', <something>`), then no special
		# processing is done and your content is sent to the client
		# more-or-less as-is, with only `Content-Length` calculation and
		# wrapping your returned object in an array (if it doesn't already
		# respond to `#each`, as required by Rack).  This allows your API to
		# return anything at all if it feels like it.
		#
		# However, by far the most common response will be a JSON document.
		# If you don't set a `Content-Type` header in your handler, then we
		# try quite hard to turn what you return from your handler into either
		# JSON (if possible), or `text/plain`.
		#
		# For starters, if what you send back responds to `#each`, then we
		# assume that you know what you're doing and will be sending back
		# strings that will come together to be valid JSON.  We'll set
		# `Content-Type` and `Link` headers to match with the handler's
		# schema, and that is that.
		#
		# If what you send back doesn't respond to `#each`, then we try to
		# determine if its valid JSON by parsing it as JSON (if it's a string)
		# or trying to call `#to_json` on it.  If either of those work, then
		# `Content-Type` and `Link` are set to match the schema for your
		# handler, and all is well.  Otherwise, we're kinda out of options and
		# we'll send back the content as `text/plain` and hope the client
		# knows what to do with it.
		#
		# @param verb [String] the **case sensitive** HTTP method which you
		#   wish this handler to respond for.  If you're using the
		#   `get`/`post/`put`/etc wrappers for `add_handler`, this argument is
		#   taken care of for you.  It's only if you want to define your own
		#   custom HTTP verbs that you'd ever need to worry about this
		#   argument.
		#
		# @param path [String, Regexp] defines the path which is to be handled
		#   by this handler.  The path is defined relative to the root of the
		#   application; that is, there may be path components in the request
		#   URI which won't be matched against, because they're handled by the
		#   webserver or Rack itself (if the app is routed to via a `map`
		#   block, for example).
		#
		#   If `path` is a string, the matching logic is very simple: if the
		#   path of the request matches exactly with `path`, then we run this
		#   handler.  If not, we skip it.
		#
		#   If `path` is a regex, things are ever so slightly more
		#   complicated.  In that instance, we'll run the handler if the given
		#   regex matches the path of the request.  In addition, any capturing
		#   subexpressions (aka "the bits in parentheses") in the regular
		#   expression will be passed as arguments to the handler block.
		#
		#   In almost all cases, you'll want to anchor your regular
		#   expressions (surround them in `^` and `$`); while it's very
		#   unlikely that you'll want to handle a URL with `/foo` anywhere in
		#   the path, we don't want to *forbid* you from doing so, so there's
		#   no automatic anchoring of regexes.
		#
		# @param block [Proc] the code to execute when this handler is
		#   invoked.  An arbitrary number of arguments may be passed to this
		#   block, if `path` is a regex which contains capturing
		#   subexpressions (that is, parts of the regular expression
		#   surrounded by unescaped parentheses).  This is useful to capture
		#   portions of the URL, such as resource IDs, and feed them into your
		#   handler as arguments.
		#
		# @raise [ArgumentError] if you don't pass in a block, or you pass an
		#   invalid type for `path`.
		#
		def add_handler(verb, path, &block)
			unless block_given?
				raise ArgumentError,
				      "Must pass a block"
			end

			@routes ||= []
			@routes << Route.new(verb, path, method_for(verb, path, block))
		end

		# :nodoc:
		# Grovel through the list of routes, looking for a match.
		#
		# @raise [Clutterbuck::Router::NotFoundError] if no route matched the
		#   given path.
		#
		# @raise [Clutterbuck::Router::MethodNotAllowedError] if a route matched
		#   the given path, but it didn't have the right verb.
		#
		def find_route(verb, path)
			if @routes.nil?
				raise Clutterbuck::Router::NotFoundError,
				      path
			end

			candidates = @routes.select { |r| r.handles?(path) }

			if candidates.empty?
				raise Clutterbuck::Router::NotFoundError,
				      path
			end

			candidates = candidates.select { |r| r.verb == verb }

			if candidates.empty?
				raise Clutterbuck::Router::MethodNotAllowedError,
				      "#{verb} not permitted on #{path}"
			end

			candidates.first
		end

		private

		# Get an unbound instance method for the given verb/path/block.
		#
		# @param verb [String]
		#
		# @param path [String, Regexp]
		#
		# @param block [Proc]
		#
		# @return [UnboundMethod]
		#
		def method_for(verb, path, block)
			name = "#{verb} #{path}".to_sym
			define_method(name, &block)
			instance_method(name).tap do |m|
				remove_method name
			end
		end
	end

	#:nodoc:
	# Add in the class-level methods to the app.
	#
	def self.included(mod)
		mod.extend(ClassMethods)
	end

	# Create a new instance of the app.
	#
	# @param env [Hash] The Rack environment for this request.
	#
	def initialize(env)
		@env = env
	end

	# Handle the request.
	#
	# Find the route, run it, and return the result.
	#
	def call
		path = env["PATH_INFO"].empty? ? "/" : env["PATH_INFO"]

		begin
			route = self.class.find_route(env["REQUEST_METHOD"], path)
		rescue Clutterbuck::Router::NotFoundError
			return [404, [["Content-Type", "text/plain"]], ["Not found"]]
		rescue Clutterbuck::Router::MethodNotAllowedError => ex
			return [405, [["Content-Type", "text/plain"]], [ex]]
		end

		route.run(self, path).tap do |response|
			if env["REQUEST_METHOD"] == "HEAD"
				response[2] = []
			end
		end
	end

	protected
	# Return the Rack environment for this request.
	def env
		@env
	end
end
