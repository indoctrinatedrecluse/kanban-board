ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "system/application_system_test_case"

module ActiveSupport
  class TestCase
    # SQLite-backed tests are more reliable in a single process on Windows.
    parallelize(workers: ENV.fetch("PARALLEL_WORKERS", 1).to_i, with: :threads)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end