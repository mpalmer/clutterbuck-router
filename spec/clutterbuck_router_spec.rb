require_relative './spec_helper'
require 'clutterbuck-router'

class RouterTestApp
	include Clutterbuck::Router

	get '/static-get' do
		[200, [], ["Ohai!"]]
	end

	get %r{^/regex-get/([^/]+)} do |arg|  #/
		[200, [], [arg]]
	end
end

describe Clutterbuck::Router do
	let(:app)     { RouterTestApp }

	let(:response) do
		app.call(
		  {
		    "REQUEST_METHOD" => request_method,
		    "PATH_INFO"      => path_info
		  }
		)
	end

	let(:status)  { response[0] }
	let(:headers) { response[1] }
	let(:body)    { response[2] }

	let(:content_type) { headers.find { |h| h[0] == "Content-Type" }.last }

	context "a simple GET request" do
		let(:request_method) { "GET" }
		let(:path_info)      { "/static-get" }

		it "is successful" do
			expect(status).to eq(200)
		end

		it "returns a body" do
			expect(body).to eq(["Ohai!"])
		end

		context "as HEAD" do
			let(:request_method) { "HEAD" }

			it "is successful" do
				expect(status).to eq(200)
			end

			it "returns no body" do
				expect(body).to eq([])
			end
		end
	end

	context "a request to a non-existent path" do
		let(:request_method) { "GET" }
		let(:path_info)      { "/non-existent" }

		it "it returns a 404" do
			expect(status).to eq(404)
		end

		it "sends back a text/plain response" do
			expect(content_type).to eq("text/plain")
		end

		it "gives an error document" do
			expect(body.join).to eq("Not found")
		end
	end

	context "POSTing to a GET-only resource" do
		let(:request_method) { "POST" }
		let(:path_info)      { "/static-get" }

		it "returns status 405" do
			expect(status).to eq(405)
		end
	end

	context "GET to a regexp route" do
		let(:request_method) { "GET" }
		let(:path_info)      { "/regex-get/foo/bar" }

		it "is successful" do
			expect(status).to eq(200)
		end

		it "gives back the captured path element" do
			expect(body).to eq(["foo"])
		end
	end
end
