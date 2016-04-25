# vi:filetype=perl

use Test::Nginx::Socket 'no_plan';
run_tests();

__DATA__

=== TEST 1: check /post fails on GET request
Sending a GET request to /post should fail
--- config
location = /post {
  if ( $request_method !~ ^POST$ ) {
    add_header Allow "POST" always;
    return 405;
  }
  echo "post succeeded";
}
--- request
GET /post
--- error_code: 405
--- response_body_like: 405 Not Allowed


=== TEST 2: check /post succeeds on POST request
Sending a POST request to /post should succeed
--- config
location = /post {
  if ( $request_method !~ ^POST$ ) {
    add_header Allow "POST" always;
    return 405;
  }
  echo "post succeeded";
}
--- request
POST /post
--- response_body
post succeeded
--- error_code: 200
