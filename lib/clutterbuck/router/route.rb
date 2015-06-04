#:nodoc:
module Clutterbuck; end
#:nodoc:
module Clutterbuck::Router; end

# A route within the application.
#
# Not something you should ever have to deal with yourself directly, it's
# part of the internal plumbing of {Clutterbuck::Router}.
#
class Clutterbuck::Router::Route
	attr_accessor :verb, :path_match

	# @param verb [String]
	#
	# @param path_match [String, Regexp]
	#
	# @param method [UnboundMethod] is a method to call on an instance of the
	#   app class this route is defined on, which will do whatever is needed
	#   to handle the route.  Because you can't just create an
	#   `UnboundMethod` out of thin air, the `UnboundMethod` needs to be
	#   created in the class, and then passed into here.  Ugly.
	#
	def initialize(verb, path_match, method)
		unless path_match.is_a?(String) or path_match.is_a?(Regexp)
			raise ArgumentError,
			      "path must be either a string or a regexp"
		end

		@verb, @path_match, @method = verb, path_match, method
	end

	# Can this route handle a request for the specified path?
	#
	# @param path [String]
	#
	# @return Boolean
	#
	def handles?(path)
		!!case @path_match
		when String
			@path_match == path
		when Regexp
			@path_match =~ path
		end
	end

	# Execute the handler for the route
	#
	# Run the method 
	def run(obj, path)
		args = case @path_match
			when String then []
			when Regexp then @path_match.match(path)[1..-1]
		end

		@method.bind(obj).call(*args)
	end
end
