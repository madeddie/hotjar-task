# vi:filetype=perl

use Test::Nginx::Socket 'no_plan';
run_tests();

__DATA__

=== TEST 1: check /get fails on POST request
Sending a POST request to /get should fail
--- config
location = /get {
  if ( $request_method !~ ^GET$ ) {
    add_header Allow "GET" always;
    return 405;
  }
  echo "get succeeded";
}
--- request
POST /get
--- error_code: 405
--- response_body_like: 405 Not Allowed


=== TEST 2: check /get succeeds on GET request
Sending a GET request to /get should succeed
--- config
location = /get {
  if ( $request_method !~ ^GET$ ) {
    add_header Allow "GET" always;
    return 405;
  }
  echo "get succeeded";
}
--- request
GET /get
--- response_body
get succeeded
--- error_code: 200
